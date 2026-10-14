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
    /// Photos marked as favourites in Photos.
    private(set) var favorites: Set<String> = []
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
        favorites = loaded.favorites
        isLoading = false
    }

    private nonisolated static func fetchAll() -> (refs: [AssetRef], byID: [String: PHAsset], favorites: Set<String>) {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: options)
        var refs: [AssetRef] = []
        var byID: [String: PHAsset] = [:]
        var favorites: Set<String> = []
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
            if asset.isFavorite { favorites.insert(asset.localIdentifier) }
        }
        return (refs, byID, favorites)
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

    /// Marks or unmarks photos as favourites in Photos. The set updates at once.
    func setFavorite(_ ids: [String], to on: Bool) async throws {
        let picked = ids.compactMap { byID[$0] }
        if on { favorites.formUnion(ids) } else { favorites.subtract(ids) }
        guard !picked.isEmpty else { return }
        try await PHPhotoLibrary.shared().performChanges {
            for asset in picked { PHAssetChangeRequest(for: asset).isFavorite = on }
        }
    }

    // MARK: Albums. Only adds and removes album membership; never deletes a photo.

    private final class IDBox: @unchecked Sendable { var value = "" }

    func albumExists(_ albumID: String) -> Bool {
        !albumID.isEmpty && collection(albumID) != nil
    }

    /// Makes a new album in Photos and returns its identifier.
    func createAlbum(titled title: String) async throws -> String {
        let box = IDBox()
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            box.value = request.placeholderForCreatedAssetCollection.localIdentifier
        }
        return box.value
    }

    func renameAlbum(_ albumID: String, to title: String) async throws {
        guard let album = collection(albumID) else { return }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCollectionChangeRequest(for: album)?.title = title
        }
    }

    func add(_ photoID: String, toAlbum albumID: String) async throws {
        guard let asset = byID[photoID], let album = collection(albumID) else { return }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCollectionChangeRequest(for: album)?.addAssets([asset] as NSArray)
        }
    }

    func remove(_ photoID: String, fromAlbum albumID: String) async throws {
        guard let asset = byID[photoID], let album = collection(albumID) else { return }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCollectionChangeRequest(for: album)?.removeAssets([asset] as NSArray)
        }
    }

    /// Photo ids in an album, newest first.
    func members(of albumID: String) async -> [String] {
        await Task.detached(priority: .userInitiated) { Self.fetchMembers(albumID) }.value
    }

    private nonisolated static func fetchMembers(_ albumID: String) -> [String] {
        guard let album = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumID], options: nil).firstObject
        else { return [] }
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        var ids: [String] = []
        PHAsset.fetchAssets(in: album, options: options).enumerateObjects { asset, _, _ in
            if asset.mediaType == .image || asset.mediaType == .video { ids.append(asset.localIdentifier) }
        }
        return ids
    }

    private func collection(_ albumID: String) -> PHAssetCollection? {
        PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumID], options: nil).firstObject
    }
}
