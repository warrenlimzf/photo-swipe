import AVFoundation
import Photos
import SwiftUI

struct AssetRef: Identifiable, Equatable {
    let id: String
    let date: Date
    let isVideo: Bool
    let duration: TimeInterval
    let pixelWidth: Int
    let pixelHeight: Int
}

/// The only file that talks to the photo library.
@MainActor @Observable
final class PhotoLibrary {
    enum Access { case unknown, granted, denied }

    private(set) var access: Access = .unknown
    private(set) var assets: [AssetRef] = []
    private(set) var isLoading = false
    private var byID: [String: PHAsset] = [:]
    private let images = PHCachingImageManager()
    private let cache = NSCache<NSString, PlatformImage>()

    init() {
        cache.countLimit = 80
        refreshAccess()
    }

    func refreshAccess() {
        access = Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func requestAccess() async {
        access = Self.map(await PHPhotoLibrary.requestAuthorization(for: .readWrite))
    }

    private static func map(_ status: PHAuthorizationStatus) -> Access {
        switch status {
        case .authorized, .limited: .granted
        case .notDetermined: .unknown
        default: .denied
        }
    }

    func reload() async {
        guard access == .granted else { return }
        isLoading = true
        let loaded = await Task.detached(priority: .userInitiated) { Self.fetchAll() }.value
        byID = loaded.byID
        assets = loaded.refs
        isLoading = false
    }

    private nonisolated static func fetchAll() -> (refs: [AssetRef], byID: [String: PHAsset]) {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: options)
        var refs: [AssetRef] = []
        var byID: [String: PHAsset] = [:]
        refs.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            guard asset.mediaType == .image || asset.mediaType == .video else { return }
            refs.append(AssetRef(
                id: asset.localIdentifier,
                date: asset.creationDate ?? .distantPast,
                isVideo: asset.mediaType == .video,
                duration: asset.duration,
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight
            ))
            byID[asset.localIdentifier] = asset
        }
        return (refs, byID)
    }

    func ref(_ id: String) -> AssetRef? {
        guard let asset = byID[id] else { return nil }
        return AssetRef(id: id, date: asset.creationDate ?? .distantPast, isVideo: asset.mediaType == .video,
                        duration: asset.duration, pixelWidth: asset.pixelWidth, pixelHeight: asset.pixelHeight)
    }

    /// `side` is in pixels. iCloud originals are downloaded when needed.
    func cachedImage(for id: String, side: CGFloat) -> PlatformImage? {
        cache.object(forKey: "\(id)#\(Int(side))" as NSString)
    }

    /// Loads images ahead of time so the next cards appear without a flash.
    func preheat(_ ids: [String], side: CGFloat) {
        Task {
            for id in ids { _ = await image(for: id, side: side) }
        }
    }

    func image(for id: String, side: CGFloat) async -> PlatformImage? {
        if let hit = cachedImage(for: id, side: side) { return hit }
        guard let asset = byID[id] else { return nil }
        let loaded = await load(asset, side: side)
        if let loaded { cache.setObject(loaded, forKey: "\(id)#\(Int(side))" as NSString) }
        return loaded
    }

    private func load(_ asset: PHAsset, side: CGFloat) async -> PlatformImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        return await withCheckedContinuation { continuation in
            var resumed = false
            images.requestImage(for: asset, targetSize: CGSize(width: side, height: side),
                                contentMode: .aspectFit, options: options) { image, _ in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: image)
            }
        }
    }

    func playerItem(for id: String) async -> AVPlayerItem? {
        guard let asset = byID[id] else { return nil }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        return await withCheckedContinuation { continuation in
            images.requestPlayerItem(forVideo: asset, options: options) { item, _ in
                continuation.resume(returning: item)
            }
        }
    }

    /// Bytes on disk for the original files of these photos.
    func totalSize(of ids: [String]) async -> Int64 {
        let picked = ids.compactMap { byID[$0] }
        return await Task.detached(priority: .utility) {
            picked.reduce(Int64(0)) { sum, asset in
                sum + PHAssetResource.assetResources(for: asset).reduce(Int64(0)) {
                    $0 + (($1.value(forKey: "fileSize") as? NSNumber)?.int64Value ?? 0)
                }
            }
        }.value
    }

    /// iOS shows its own confirmation; deleted photos go to Recently Deleted for 30 days.
    func delete(_ ids: [String]) async throws {
        let picked = ids.compactMap { byID[$0] }
        guard !picked.isEmpty else { return }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(picked as NSArray)
        }
    }
}
