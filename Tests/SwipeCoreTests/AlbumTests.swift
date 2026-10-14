import Foundation
import Testing
@testable import SwipeCore

@Test func oldSaveFilesStillLoad() throws {
    let old = #"{"decisions":{"a":"keep"},"bookmarks":["b"],"deletedCount":3,"bytesFreed":10,"activeDays":["2026-10-14"]}"#
    let state = try JSONDecoder().decode(ReviewState.self, from: Data(old.utf8))
    #expect(state.decisions == ["a": .keep])
    #expect(state.bookmarks == ["b"])
    #expect(state.deletedCount == 3)
    #expect(state.shelf.isEmpty)
}

@Test func shelfStartsEmptyAndRoundTrips() throws {
    var state = ReviewState()
    #expect(state.shelf.isEmpty)
    state.addToShelf(ShelfAlbum(id: "s1", emoji: "⛳", name: "Golf", albumID: "PH1"))
    let back = try JSONDecoder().decode(ReviewState.self, from: JSONEncoder().encode(state))
    #expect(back == state)
    #expect(back.shelf[0].title == "⛳ Golf")
}

@Test func shelfEditsKeepOrder() {
    var state = ReviewState()
    state.addToShelf(ShelfAlbum(id: "s1", emoji: "⛳", name: "Golf"))
    state.addToShelf(ShelfAlbum(id: "s2", emoji: "💕", name: "Girlfriend"))
    state.updateShelf("s1", emoji: "🏌️", name: "Golf swings")
    state.setAlbumID("PH9", for: "s2")
    #expect(state.shelf.map(\.title) == ["🏌️ Golf swings", "💕 Girlfriend"])
    #expect(state.shelf[1].albumID == "PH9")
    state.removeFromShelf("s1")
    #expect(state.shelf.map(\.id) == ["s2"])
}

@Test func resetProgressKeepsAlbums() {
    var state = ReviewState()
    state.decide("a", .keep, day: "d")
    state.toggleBookmark("a")
    state.addToShelf(ShelfAlbum(id: "s1", emoji: "⛳", name: "Golf"))
    state.resetProgress()
    #expect(state.decisions.isEmpty)
    #expect(state.bookmarks.isEmpty)
    #expect(state.shelf.map(\.id) == ["s1"])
}

@Test func emojiInputKeepsOneWholeEmoji() {
    #expect(AlbumInput.emoji(from: "⛳") == "⛳")
    #expect(AlbumInput.emoji(from: "⛳💕") == "💕")
    #expect(AlbumInput.emoji(from: "❤️") == "❤️")
    #expect(AlbumInput.emoji(from: "👨‍👩‍👧") == "👨‍👩‍👧")
    #expect(AlbumInput.emoji(from: "🇸🇬") == "🇸🇬")
    #expect(AlbumInput.emoji(from: "👍🏽") == "👍🏽")
    #expect(AlbumInput.emoji(from: "golf") == nil)
    #expect(AlbumInput.emoji(from: "1") == nil)
    #expect(AlbumInput.emoji(from: "") == nil)
}

@Test func albumNameIsTrimmedAndCapped() {
    #expect(AlbumInput.name(from: "  Golf  ") == "Golf")
    #expect(AlbumInput.name(from: "Nice\nshots") == "Nice shots")
    #expect(AlbumInput.name(from: "   ") == nil)
    #expect(AlbumInput.name(from: String(repeating: "a", count: 40))?.count == 24)
}

@Test func undoOnlyTakesBackWhatTheSwipeAdded() {
    let members: [String: Set<String>] = ["golf": ["p1"], "gf": []]
    let fresh = FilingLedger.newAlbums(for: "p1", selected: ["golf", "gf"], shelfOrder: ["golf", "gf", "nice"], members: members)
    #expect(fresh == ["gf"])
    var ledger = FilingLedger()
    ledger.record("p1", albums: fresh)
    #expect(ledger.takeBack("p1") == ["gf"])
    #expect(ledger.takeBack("p1") == [])
}

@Test func filingFollowsRailOrderAndIgnoresRemovedAlbums() {
    #expect(FilingLedger.newAlbums(for: "p", selected: ["b", "a", "gone"], shelfOrder: ["a", "b"], members: [:]) == ["a", "b"])
    var ledger = FilingLedger()
    ledger.record("p", albums: ["a"])
    ledger.record("p", albums: [])
    #expect(ledger.takeBack("p") == [])
}

@Test func albumDeckCanOfferEveryPhoto() {
    var state = ReviewState()
    state.decide("a", .keep, day: "d")
    #expect(ReviewSession(ids: ["a", "b"], state: state).ids == ["b"])
    #expect(ReviewSession(ids: ["a", "b"], state: state, onlyUndecided: false).ids == ["a", "b"])
}
