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

/// Which albums each swipe put a photo into, so undo can take it back out. Lives for one deck.
public struct FilingLedger: Equatable, Sendable {
    private var added: [String: [String]] = [:]

    public init() {}

    /// The selected albums (in rail order) the photo is not already in.
    public static func newAlbums(for photo: String, selected: Set<String>, shelfOrder: [String],
                                 members: [String: Set<String>]) -> [String] {
        shelfOrder.filter { selected.contains($0) && !(members[$0]?.contains(photo) ?? false) }
    }

    public mutating func record(_ photo: String, albums: [String]) {
        added[photo] = albums.isEmpty ? nil : albums
    }

    /// The albums to remove the photo from, once. Empty when the swipe filed nothing.
    public mutating func takeBack(_ photo: String) -> [String] {
        added.removeValue(forKey: photo) ?? []
    }
}
