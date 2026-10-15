import Foundation

/// One of the user's emoji albums on the swipe screen's rail. Backed by a real album in Photos.
public struct ShelfAlbum: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var emoji: String
    public var name: String
    /// `PHAssetCollection.localIdentifier`. Empty until the Photos album exists.
    public var albumID: String

    public init(id: String = UUID().uuidString, emoji: String, name: String, albumID: String = "") {
        self.id = id
        self.emoji = emoji
        self.name = name
        self.albumID = albumID
    }

    /// The album's title in Photos, e.g. "⛳ Golf".
    public var title: String { "\(emoji) \(name)" }
}

/// Cleans what the user types in the new-album sheet.
public enum AlbumInput {
    public static let maxNameLength = 24

    /// The last emoji typed, or nil if there is none. Flags, skin tones and families stay whole.
    public static func emoji(from text: String) -> String? {
        text.last(where: isEmoji).map(String.init)
    }

    static func isEmoji(_ c: Character) -> Bool {
        guard let first = c.unicodeScalars.first else { return false }
        if first.properties.isEmojiPresentation { return true }
        // "❤️" and "1️⃣" carry a variation selector; a bare "1" or "#" does not count.
        return first.properties.isEmoji && c.unicodeScalars.count > 1
    }

    /// One line, trimmed, at most 24 characters. Nil when empty.
    public static func name(from text: String) -> String? {
        let cleaned = text.components(separatedBy: .newlines).joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? nil : String(cleaned.prefix(maxNameLength))
    }
}

/// Which albums each swipe put a photo into (and took it out of), so undo can reverse it. Lives for one deck.
public struct FilingLedger: Equatable, Sendable {
    private var added: [String: [String]] = [:]
    private var movedOut: [String: [String]] = [:]

    public init() {}

    /// The selected albums (in rail order) the photo is not already in.
    public static func newAlbums(for photo: String, selected: Set<String>, shelfOrder: [String],
                                 members: [String: Set<String>]) -> [String] {
        shelfOrder.filter { selected.contains($0) && !(members[$0]?.contains(photo) ?? false) }
    }

    /// The other rail albums (in rail order) already holding the photo. A photo lives in one
    /// emoji album at a time, so filing it into `target` takes it out of these.
    public static func otherAlbums(for photo: String, target: String, shelfOrder: [String],
                                   members: [String: Set<String>]) -> [String] {
        shelfOrder.filter { $0 != target && (members[$0]?.contains(photo) ?? false) }
    }

    public mutating func record(_ photo: String, albums: [String], movedOutOf: [String] = []) {
        added[photo] = albums.isEmpty ? nil : albums
        movedOut[photo] = movedOutOf.isEmpty ? nil : movedOutOf
    }

    /// How many photos this deck has put into each album, for the finish screen.
    public var filedCounts: [String: Int] {
        added.values.reduce(into: [:]) { counts, albums in
            for album in albums { counts[album, default: 0] += 1 }
        }
    }

    /// The albums to remove the photo from, once. Empty when the swipe filed nothing.
    public mutating func takeBack(_ photo: String) -> [String] {
        added.removeValue(forKey: photo) ?? []
    }

    /// The albums to put the photo back into, once. Empty when the swipe moved nothing.
    public mutating func takeBackMoves(_ photo: String) -> [String] {
        movedOut.removeValue(forKey: photo) ?? []
    }
}
