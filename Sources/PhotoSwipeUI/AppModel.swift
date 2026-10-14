import SwiftUI
import SwipeCore

/// A stack of photos to swipe through.
struct Deck: Identifiable {
    let id = UUID()
    /// Also names the card the deck zooms out of.
    let title: String
    let ids: [String]
    /// True for an album being cleaned up: offer every photo, not just undecided ones.
    var everyPhoto = false
}

@MainActor @Observable
public final class AppModel {
    let library = PhotoLibrary()
    private(set) var state: ReviewState
    private(set) var months: [MonthGroup] = []
    private(set) var onThisDay: [String] = []
    /// Photo ids in each emoji album, newest first. Keyed by `ShelfAlbum.id`.
    private(set) var albumMembers: [String: [String]] = [:]
    /// A short notice when Photos refuses an album change. The swipe screen shows and clears it.
    var albumError: String?
    private var albumQueue: Task<Void, Never>?
    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "haptics") }
    }

    private let fileURL: URL
    private var saveTask: Task<Void, Never>?
    let calendar = Calendar.current

    public init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("review-state.json")
        state = StateFile.load(from: fileURL)
        hapticsEnabled = UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true
    }

    var today: String { DayStamp.string(Date(), calendar: calendar) }
    var streak: Int { Streak.current(activeDays: state.activeDays, today: Date(), calendar: calendar) }
    var allIDs: [String] { library.assets.map(\.id) }
    var videoIDs: [String] { library.assets.filter(\.isVideo).map(\.id) }
    var bookmarkIDs: [String] { library.assets.map(\.id).filter(state.bookmarks.contains) }
    var reviewedFraction: Double {
        library.assets.isEmpty ? 0 : Double(state.progress(of: allIDs).done) / Double(library.assets.count)
    }
    /// The last seven days, oldest first, with whether each had a swipe.
    var lastWeek: [(label: String, active: Bool)] {
        (0..<7).reversed().compactMap { back in
            guard let day = calendar.date(byAdding: .day, value: -back, to: Date()) else { return nil }
            let symbol = calendar.veryShortWeekdaySymbols[calendar.component(.weekday, from: day) - 1]
            return (symbol, state.activeDays.contains(DayStamp.string(day, calendar: calendar)))
        }
    }

    func reload() async {
        await library.reload()
        let dated = library.assets.map { DatedID(id: $0.id, date: $0.date) }
        months = Grouping.byMonth(dated, calendar: calendar)
        onThisDay = Grouping.onThisDay(dated, today: Date(), calendar: calendar)
        if !library.assets.isEmpty {
            apply { $0.prune(existing: Set(dated.map(\.id))) }
        }
        await refreshAlbums()
    }

    /// Every change to saved state goes through here so it is written to disk.
    func apply(_ change: (inout ReviewState) -> Void) {
        change(&state)
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    public func saveNow() {
        try? StateFile.save(state, to: fileURL)
    }

    /// Returns false when the user cancels the system prompt or the delete fails.
    func commitDeletes(_ ids: [String]) async -> Bool {
        let bytes = await library.totalSize(of: ids)
        do {
            try await library.delete(ids)
        } catch {
            return false
        }
        apply { $0.commitDeletion(ids: ids, bytes: bytes) }
        saveNow()
        await reload()
        return true
    }

    func refreshAlbums() async {
        var result: [String: [String]] = [:]
        for album in state.shelf where !album.albumID.isEmpty {
            result[album.id] = await library.members(of: album.albumID)
        }
        albumMembers = result
    }

    /// Makes the album in Photos and puts its emoji at the bottom of the rail. Returns the shelf id.
    func createShelfAlbum(emoji: String, name: String) async throws -> String {
        var album = ShelfAlbum(emoji: emoji, name: name)
        album.albumID = try await library.createAlbum(titled: album.title)
        apply { $0.addToShelf(album) }
        albumMembers[album.id] = []
        return album.id
    }

    func editShelfAlbum(_ id: String, emoji: String, name: String) async throws {
        apply { $0.updateShelf(id, emoji: emoji, name: name) }
        guard let album = state.shelf.first(where: { $0.id == id }), library.albumExists(album.albumID) else { return }
        try await library.renameAlbum(album.albumID, to: album.title)
    }

    func removeFromShelf(_ id: String) {
        apply { $0.removeFromShelf(id) }
        albumMembers[id] = nil
    }

    /// Adds a kept photo to albums. The count updates at once; Photos catches up in order.
    func file(_ photo: String, into shelfIDs: [String]) {
        guard !shelfIDs.isEmpty else { return }
        for id in shelfIDs { albumMembers[id, default: []].insert(photo, at: 0) }
        enqueue { [self] in
            for id in shelfIDs {
                guard let albumID = try await liveAlbumID(id) else { continue }
                try await library.add(photo, toAlbum: albumID)
                // A recreated album starts empty, so put this photo back in its count.
                if !(albumMembers[id]?.contains(photo) ?? false) { albumMembers[id, default: []].insert(photo, at: 0) }
            }
        }
    }

    func unfile(_ photo: String, from shelfIDs: [String]) {
        guard !shelfIDs.isEmpty else { return }
        for id in shelfIDs { albumMembers[id]?.removeAll { $0 == photo } }
        enqueue { [self] in
            for id in shelfIDs {
                guard let album = state.shelf.first(where: { $0.id == id }), library.albumExists(album.albumID) else { continue }
                try await library.remove(photo, fromAlbum: album.albumID)
            }
        }
    }

    /// The album's Photos id, recreating the album if the user deleted it in Photos.
    private func liveAlbumID(_ shelfID: String) async throws -> String? {
        guard let album = state.shelf.first(where: { $0.id == shelfID }) else { return nil }
        if library.albumExists(album.albumID) { return album.albumID }
        let fresh = try await library.createAlbum(titled: album.title)
        apply { $0.setAlbumID(fresh, for: shelfID) }
        // The old album's photos went with it; the count must not keep them.
        albumMembers[shelfID] = []
        return fresh
    }

    /// Album writes run one after another, so an undo never overtakes the add it reverses.
    private func enqueue(_ work: @escaping @MainActor () async throws -> Void) {
        let previous = albumQueue
        albumQueue = Task { [weak self] in
            await previous?.value
            do {
                try await work()
            } catch {
                self?.albumError = "Couldn't update the album in Photos"
                await self?.refreshAlbums()
            }
        }
    }

    func resetProgress() {
        apply { $0.resetProgress() }
        saveNow()
    }
}
