import Foundation

public enum Decision: String, Codable, Sendable {
    case keep, delete
}

/// Everything the app remembers between launches. Keyed by the photo's library identifier.
public struct ReviewState: Codable, Equatable, Sendable {
    public var decisions: [String: Decision] = [:]
    public var bookmarks: Set<String> = []
    /// Lifetime totals for photos actually removed from the library.
    public var deletedCount = 0
    public var bytesFreed: Int64 = 0
    /// Days ("yyyy-MM-dd") with at least one swipe, for the streak.
    public var activeDays: Set<String> = []
    /// The user's emoji albums, in rail order. Starts empty.
    public var shelf: [ShelfAlbum] = []

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        decisions = try c.decodeIfPresent([String: Decision].self, forKey: .decisions) ?? [:]
        bookmarks = try c.decodeIfPresent(Set<String>.self, forKey: .bookmarks) ?? []
        deletedCount = try c.decodeIfPresent(Int.self, forKey: .deletedCount) ?? 0
        bytesFreed = try c.decodeIfPresent(Int64.self, forKey: .bytesFreed) ?? 0
        activeDays = try c.decodeIfPresent(Set<String>.self, forKey: .activeDays) ?? []
        shelf = try c.decodeIfPresent([ShelfAlbum].self, forKey: .shelf) ?? []
    }

    public var keptCount: Int { decisions.values.filter { $0 == .keep }.count }
    public var pendingDeletes: [String] { decisions.filter { $0.value == .delete }.map(\.key).sorted() }
    public var reviewedCount: Int { decisions.count + deletedCount }

    public mutating func decide(_ id: String, _ decision: Decision, day: String) {
        decisions[id] = decision
        activeDays.insert(day)
    }

    public mutating func clearDecision(_ id: String) {
        decisions[id] = nil
    }

    public mutating func toggleBookmark(_ id: String) {
        if bookmarks.contains(id) { bookmarks.remove(id) } else { bookmarks.insert(id) }
    }

    /// Call after the system has really deleted these photos.
    public mutating func commitDeletion(ids: [String], bytes: Int64) {
        for id in ids {
            decisions[id] = nil
            bookmarks.remove(id)
        }
        deletedCount += ids.count
        bytesFreed += bytes
    }

    public mutating func addToShelf(_ album: ShelfAlbum) {
        shelf.append(album)
    }

    public mutating func updateShelf(_ id: String, emoji: String, name: String) {
        guard let i = shelf.firstIndex(where: { $0.id == id }) else { return }
        shelf[i].emoji = emoji
        shelf[i].name = name
    }

    public mutating func setAlbumID(_ albumID: String, for id: String) {
        guard let i = shelf.firstIndex(where: { $0.id == id }) else { return }
        shelf[i].albumID = albumID
    }

    /// Takes the emoji off the rail. The album in Photos is left alone.
    public mutating func removeFromShelf(_ id: String) {
        shelf.removeAll { $0.id == id }
    }

    /// Clears decisions, bookmarks and stats. The albums stay: they are real albums in Photos.
    public mutating func resetProgress() {
        let kept = shelf
        self = ReviewState()
        shelf = kept
    }

    /// Drop anything that points at a photo no longer in the library.
    public mutating func prune(existing: Set<String>) {
        decisions = decisions.filter { existing.contains($0.key) }
        bookmarks = bookmarks.intersection(existing)
    }

    public func progress(of ids: [String]) -> (done: Int, total: Int) {
        (ids.reduce(0) { $0 + (decisions[$1] == nil ? 0 : 1) }, ids.count)
    }
}

public enum StateFile {
    public static func load(from url: URL) -> ReviewState {
        guard let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(ReviewState.self, from: data) else { return ReviewState() }
        return state
    }

    public static func save(_ state: ReviewState, to url: URL) throws {
        try JSONEncoder().encode(state).write(to: url, options: .atomic)
    }
}
