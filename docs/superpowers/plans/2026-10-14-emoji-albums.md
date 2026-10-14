# Emoji Albums Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (recommended here) or superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user sort photos into real Apple Photos albums while swiping: tap emoji icons on a rail at the right of the swipe screen, swipe right, and the photo is kept and added to those albums.

**Architecture:** Pure logic (album list, emoji/name input cleaning, undo ledger) goes in `SwipeCore` with tests. PhotoKit album writes go in `PhotoLibrary.swift` only. `AppModel` holds album membership and runs album writes one after another. Three small new view files: the rail, the create/edit sheet, the home Albums section plus the album page.

**Tech Stack:** Swift 6 toolchain (Swift 5 language mode), SwiftUI, PhotoKit, Swift Testing. iOS 18.

**Spec:** this file, section "What Warren asked for" (agreed with Warren in chat, 14 Oct 2026). Read `CLAUDE.md` in the repo root first: its invariants and the Gallery look still apply.

---

## What Warren asked for (the design, agreed)

**Swipe screen**
- A narrow **rail down the right edge** of the swipe screen, beside the photo, under the top bar. Emoji only (space is tight), one round button per album, a **＋ at the bottom**.
- **First launch: the rail is just ＋.** No default albums (no Golf etc.). Every album the user makes is saved and shown on every deck from then on. The list scrolls when it gets long.
- **＋** opens a small sheet: pick one emoji (native emoji keyboard) and type a name. Create makes a **real album in Apple Photos** titled `"<emoji> <name>"` (e.g. "⛳ Golf"), adds the emoji to the bottom of the rail, and selects it.
- **Tap an emoji** to select it. The name pops out beside it in a small bubble for about 1.2 s, then fades. Selected emojis get a green ring (the keep colour) and grow slightly.
- **Selection stays on** between photos until tapped off (bursts of 20 golf shots = 20 right-swipes). It resets when the deck is closed.
- **Swipe right (or the ✓ button)** keeps the photo and adds it straight into every selected album. While dragging right, the "Keep" stamp shows the selected emojis ("Keep ⛳💕") so the user sees where it goes.
- **Swipe left** deletes as today (review grid + iOS prompt). Album selection is ignored for deletes.
- **Undo** takes the photo back out of the albums that swipe added it to (never out of an album it was already in).
- Long-press an emoji: **Edit** (emoji/name, renames the Photos album) or **Remove from rail** (the Photos album and its photos stay).

**Home screen**
- Under the stats line: an **Albums** list. Each row: cover photo, "⛳ Golf", photo count, chevron. Last row: **＋ New album**.
- Tap a row: the album page. Photos edge to edge, newest first. **Swipe** button runs the normal deck on every photo in that album (to clean it further). Tap a photo to start swiping from it. Long-press a photo: **Remove from album**. Menu: Edit, Open Photos, Remove from rail.

**Motion (must be there, keep it light)**
- Rail emojis: spring in when created (scale 0.6 → 1 + fade), spring select/deselect (ring + 1.06 scale), haptic tick on tap.
- Name bubble: slides out from the emoji and fades out after 1.2 s.
- Keep stamp: emojis appear inside it as the card is dragged right.
- Home Albums rows and counts: `.numericText()` on counts, rows fade in when added.
- Respect Reduce Motion the same way the deck already does.

**Out of scope:** iCloud Shared Albums (Apple gives apps no write access), per-photo notes, reordering the rail.

## Global Constraints

- **Never delete a photo** as part of album work. Album code only adds/removes album membership.
- **Photos never leave the phone.** No network code, no SDKs.
- **Gallery look** (CLAUDE.md): dark canvas, system font, no accent colour; green `Theme.keep` is the only colour used for "selected/keep".
- **Swipes never block.** `decide()` stays instant; album writes run in the background.
- Logic in `SwipeCore` with a test first; views stay thin.
- Old save files (`review-state.json` from v1.0.0) must still load with all progress.
- "Reset progress" in Settings must NOT remove the user's albums.
- Version after this work: **1.1.0** (`MARKETING_VERSION`), build **2** (`CURRENT_PROJECT_VERSION`).

## Review Focus

1. **v1.0.0 save file without the new `shelf` key** → loads with all progress (test in Task 1).
2. **Reset progress** → decisions/bookmarks/stats cleared, albums kept (test in Task 1).
3. **Photo already in the album, swiped right again, then undo** → stays in the album (test in Task 1).
4. **User deleted the album inside the Photos app** → next right-swipe quietly recreates it (Task 2 `liveAlbumID`, checked in Task 6).
5. **Swipe then instant undo** → the remove must not run before the add finishes (Task 2 `enqueue` runs writes in order, checked in Task 6).

---

### Task 1: Album logic in SwipeCore

**Files:**
- Create: `Sources/SwipeCore/Albums.swift`
- Modify: `Sources/SwipeCore/ReviewState.swift`, `Sources/SwipeCore/ReviewSession.swift`
- Test: `Tests/SwipeCoreTests/AlbumTests.swift`

**Interfaces:**
- Produces: `ShelfAlbum(id:emoji:name:albumID:)` with `.title`; `ReviewState.shelf`, `addToShelf(_:)`, `updateShelf(_:emoji:name:)`, `setAlbumID(_:for:)`, `removeFromShelf(_:)`, `resetProgress()`; `AlbumInput.emoji(from:) -> String?`, `AlbumInput.name(from:) -> String?`; `FilingLedger.newAlbums(for:selected:shelfOrder:members:) -> [String]`, `record(_:albums:)`, `takeBack(_:) -> [String]`; `ReviewSession(ids:state:onlyUndecided:)`.

- [ ] **Step 1: Write the failing tests** in `Tests/SwipeCoreTests/AlbumTests.swift`

```swift
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
```

- [ ] **Step 2: Run to see them fail**

Run: `./test.sh`
Expected: compile errors (`ShelfAlbum`, `AlbumInput`, `FilingLedger` not found).

- [ ] **Step 3: Create `Sources/SwipeCore/Albums.swift`**

```swift
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
```

- [ ] **Step 4: Modify `Sources/SwipeCore/ReviewState.swift`**

Add the property after `activeDays`:

```swift
    /// The user's emoji albums, in rail order. Starts empty.
    public var shelf: [ShelfAlbum] = []
```

Add right after `public init() {}` (a hand-written decoder so v1.0.0 files without `shelf` still load):

```swift
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        decisions = try c.decodeIfPresent([String: Decision].self, forKey: .decisions) ?? [:]
        bookmarks = try c.decodeIfPresent(Set<String>.self, forKey: .bookmarks) ?? []
        deletedCount = try c.decodeIfPresent(Int.self, forKey: .deletedCount) ?? 0
        bytesFreed = try c.decodeIfPresent(Int64.self, forKey: .bytesFreed) ?? 0
        activeDays = try c.decodeIfPresent(Set<String>.self, forKey: .activeDays) ?? []
        shelf = try c.decodeIfPresent([ShelfAlbum].self, forKey: .shelf) ?? []
    }
```

Add before `prune(existing:)`:

```swift
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
```

- [ ] **Step 5: Modify `ReviewSession.init` in `Sources/SwipeCore/ReviewSession.swift`**

```swift
    /// Starts on the photos not yet decided. If all are decided, or `onlyUndecided` is false
    /// (an album being cleaned up), the whole stack is offered.
    public init(ids: [String], state: ReviewState, onlyUndecided: Bool = true) {
        let undecided = ids.filter { state.decisions[$0] == nil }
        self.ids = !onlyUndecided || undecided.isEmpty ? ids : undecided
    }
```

- [ ] **Step 6: Run tests**

Run: `./test.sh`
Expected: all tests pass (the 11 old ones + 9 new).

- [ ] **Step 7: Commit and push**

```bash
git add Sources/SwipeCore Tests/SwipeCoreTests/AlbumTests.swift
git commit -m "SwipeCore: emoji albums (shelf, input cleaning, undo ledger)"
git push origin main
```

---

### Task 2: Album writes (PhotoLibrary + AppModel)

**Files:**
- Modify: `Sources/PhotoSwipeUI/PhotoLibrary.swift` (append a section at the end of the class)
- Modify: `Sources/PhotoSwipeUI/AppModel.swift`
- Modify: `Sources/PhotoSwipeUI/Platform.swift` (one helper)

**Interfaces:**
- Consumes: Task 1 types.
- Produces on `AppModel`: `albumMembers: [String: [String]]` (shelf id → photo ids, newest first), `albumError: String?`, `refreshAlbums() async`, `createShelfAlbum(emoji:name:) async throws -> String`, `editShelfAlbum(_:emoji:name:) async throws`, `removeFromShelf(_:)`, `file(_:into:)`, `unfile(_:from:)`. Global `openPhotosApp()`.

- [ ] **Step 1: Append to `PhotoLibrary` (inside the class, after `delete`)**

```swift
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
```

- [ ] **Step 2: Add to `AppModel`**

Properties (after `onThisDay`):

```swift
    /// Photo ids in each emoji album, newest first. Keyed by `ShelfAlbum.id`.
    private(set) var albumMembers: [String: [String]] = [:]
    /// A short notice when Photos refuses an album change. The swipe screen shows and clears it.
    var albumError: String?
    private var albumQueue: Task<Void, Never>?
```

At the end of `reload()` add `await refreshAlbums()`.

Change `resetProgress()` to use `apply { $0.resetProgress() }` instead of `apply { $0 = ReviewState() }`.

New methods (before `resetProgress`):

```swift
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
```

- [ ] **Step 3: Add to `Platform.swift`, next to `openSystemSettings()`**

```swift
/// Apple lets apps open Photos but not a specific album.
func openPhotosApp() {
    #if canImport(UIKit)
    if let url = URL(string: "photos-redirect://") { UIApplication.shared.open(url) }
    #endif
}
```

- [ ] **Step 4: Type-check and test**

Run: `swift build && ./test.sh`
Expected: builds clean, all tests pass.

- [ ] **Step 5: Commit and push**

```bash
git add Sources/PhotoSwipeUI
git commit -m "Album writes: create, rename, add, remove; ordered queue; recreate deleted albums"
git push origin main
```

---

### Task 3: New-album sheet

**Files:**
- Create: `Sources/PhotoSwipeUI/AlbumEditor.swift`

**Interfaces:**
- Consumes: `AppModel.createShelfAlbum`, `editShelfAlbum`, `AlbumInput`.
- Produces: `enum EditorTarget: Identifiable { case new, edit(ShelfAlbum) }` with `.album: ShelfAlbum?`; `AlbumEditor(editing: ShelfAlbum?, onCreated: (String) -> Void)`.

- [ ] **Step 1: Create `Sources/PhotoSwipeUI/AlbumEditor.swift`**

```swift
import SwiftUI
import SwipeCore

/// What the album sheet is open for.
enum EditorTarget: Identifiable {
    case new
    case edit(ShelfAlbum)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let album): album.id
        }
    }

    var album: ShelfAlbum? {
        if case .edit(let album) = self { album } else { nil }
    }
}

/// Create or edit an emoji album: one emoji, one short name. Creating also makes the album in Photos.
struct AlbumEditor: View {
    let editing: ShelfAlbum?
    /// Called with the new shelf id after a create, so the swipe screen can select it.
    var onCreated: (String) -> Void = { _ in }
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var emojiText = ""
    @State private var nameText = ""
    @State private var isSaving = false
    @State private var error: String?

    private var emoji: String? { AlbumInput.emoji(from: emojiText) }
    private var name: String? { AlbumInput.name(from: nameText) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                EmojiField(text: $emojiText, focusOnAppear: editing == nil)
                    .frame(width: 104, height: 104)
                    .background(Theme.card, in: Circle())
                    .overlay { Circle().strokeBorder(Theme.hairline) }
                Text(emoji == nil ? "Tap the circle, pick an emoji" : "Emoji").eyebrow()
                TextField("Name, e.g. Golf", text: $nameText)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.ink)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 1) }
                    .padding(.horizontal, 32)
                if let emoji, let name {
                    Text("Album in Photos: \(emoji) \(name)")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                        .transition(.opacity)
                }
                if let error {
                    Text(error).font(.footnote).foregroundStyle(Theme.delete).multilineTextAlignment(.center)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 24)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .animation(.easeOut(duration: 0.2), value: emoji != nil && name != nil)
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle(editing == nil ? "New album" : "Edit album")
            .inlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "Create" : "Save", action: save)
                        .disabled(emoji == nil || name == nil || isSaving)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            emojiText = editing?.emoji ?? ""
            nameText = editing?.name ?? ""
        }
    }

    private func save() {
        guard let emoji, let name, !isSaving else { return }
        isSaving = true
        Task {
            do {
                if let editing {
                    try await model.editShelfAlbum(editing.id, emoji: emoji, name: name)
                } else {
                    let id = try await model.createShelfAlbum(emoji: emoji, name: name)
                    onCreated(id)
                }
                Haptics.success(model.hapticsEnabled)
                dismiss()
            } catch {
                self.error = "Photos didn't allow that. Give Photo Swipe full photo access in Settings."
                isSaving = false
            }
        }
    }
}

#if canImport(UIKit)
import UIKit

/// A text field that opens straight on the emoji keyboard and keeps only one emoji.
struct EmojiField: UIViewRepresentable {
    @Binding var text: String
    var focusOnAppear = false

    final class Field: UITextField {
        override var textInputContextIdentifier: String? { "" }
        override var textInputMode: UITextInputMode? {
            UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" } ?? super.textInputMode
        }
    }

    func makeUIView(context: Context) -> Field {
        let field = Field()
        field.font = .systemFont(ofSize: 54)
        field.textAlignment = .center
        field.tintColor = .clear
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        if focusOnAppear { DispatchQueue.main.async { field.becomeFirstResponder() } }
        return field
    }

    func updateUIView(_ field: Field, context: Context) {
        if field.text != text { field.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject {
        let text: Binding<String>
        init(text: Binding<String>) { self.text = text }

        @objc func changed(_ field: UITextField) {
            let picked = AlbumInput.emoji(from: field.text ?? "") ?? ""
            field.text = picked
            text.wrappedValue = picked
        }
    }
}
#else
/// Mac stand-in so the package type-checks. The product is iPhone only.
struct EmojiField: View {
    @Binding var text: String
    var focusOnAppear = false

    var body: some View {
        TextField("🙂", text: $text).font(.system(size: 54)).multilineTextAlignment(.center)
    }
}
#endif
```

- [ ] **Step 2: Type-check**

Run: `swift build`
Expected: builds clean.

- [ ] **Step 3: Commit and push**

```bash
git add Sources/PhotoSwipeUI/AlbumEditor.swift
git commit -m "New-album sheet: emoji keyboard field + name, creates the Photos album"
git push origin main
```

---

### Task 4: The rail on the swipe screen

**Files:**
- Create: `Sources/PhotoSwipeUI/AlbumRail.swift`
- Modify: `Sources/PhotoSwipeUI/SwipeDeckView.swift`
- Modify: `Sources/PhotoSwipeUI/AppModel.swift` (`Deck` gets one field)

**Interfaces:**
- Consumes: Task 1 `FilingLedger`, Task 2 `file/unfile/albumMembers/albumError/removeFromShelf`, Task 3 `EditorTarget/AlbumEditor`.
- Produces: `AlbumRail(selected: Binding<Set<String>>, onAdd: () -> Void, onEdit: (ShelfAlbum) -> Void)`; `Deck(title:ids:everyPhoto:)`.

- [ ] **Step 1: Create `Sources/PhotoSwipeUI/AlbumRail.swift`**

```swift
import SwiftUI
import SwipeCore

/// The emoji albums down the right edge of the swipe screen. Tap to select (it stays on), ＋ to add.
struct AlbumRail: View {
    @Binding var selected: Set<String>
    let onAdd: () -> Void
    let onEdit: (ShelfAlbum) -> Void
    @Environment(AppModel.self) private var model
    @State private var bubble: String?
    @State private var bubbleTask: Task<Void, Never>?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(model.state.shelf) { album in
                    emojiButton(album)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
                addButton
            }
            .padding(.vertical, 4)
            .animation(.spring(duration: 0.35, bounce: 0.3), value: model.state.shelf.map(\.id))
        }
        // The name bubble pokes out to the left of the rail.
        .scrollClipDisabled()
        .frame(width: 50)
    }

    private func emojiButton(_ album: ShelfAlbum) -> some View {
        let isOn = selected.contains(album.id)
        return Button { toggle(album) } label: {
            Text(album.emoji)
                .font(.system(size: 24))
                .frame(width: 46, height: 46)
                .background(.ultraThinMaterial, in: Circle())
                .overlay { Circle().strokeBorder(isOn ? Theme.keep : Theme.hairline, lineWidth: isOn ? 2.5 : 1) }
                .scaleEffect(isOn ? 1.06 : 1)
                .opacity(selected.isEmpty || isOn ? 1 : 0.7)
        }
        .buttonStyle(PressStyle())
        .overlay(alignment: .trailing) {
            if bubble == album.id {
                NameBubble(name: album.name, isOn: isOn)
                    .offset(x: -56)
                    .transition(.offset(x: 16).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .zIndex(bubble == album.id ? 1 : 0)
        .contextMenu {
            Button("Edit", systemImage: "pencil") { onEdit(album) }
            Button("Remove from rail", systemImage: "minus.circle") {
                selected.remove(album.id)
                model.removeFromShelf(album.id)
            }
        }
        .accessibilityLabel("\(album.name) album")
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityHint("When selected, every photo you keep is added to this album")
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 46, height: 46)
                .overlay { Circle().strokeBorder(Theme.ink.opacity(0.35), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])) }
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel("New album")
    }

    private func toggle(_ album: ShelfAlbum) {
        Haptics.tick(model.hapticsEnabled)
        withAnimation(.spring(duration: 0.3, bounce: 0.35)) {
            if selected.contains(album.id) { selected.remove(album.id) } else { selected.insert(album.id) }
            bubble = album.id
        }
        bubbleTask?.cancel()
        bubbleTask = Task {
            try? await Task.sleep(for: .milliseconds(1200))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { bubble = nil }
        }
    }
}

/// The album's name, shown for a moment when its emoji is tapped.
private struct NameBubble: View {
    let name: String
    let isOn: Bool

    var body: some View {
        Label(name, systemImage: isOn ? "checkmark" : "xmark")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .fixedSize()
    }
}
```

- [ ] **Step 2: `Deck` in `AppModel.swift` gets a flag**

```swift
struct Deck: Identifiable {
    let id = UUID()
    /// Also names the card the deck zooms out of.
    let title: String
    let ids: [String]
    /// True for an album being cleaned up: offer every photo, not just undecided ones.
    var everyPhoto = false
}
```

- [ ] **Step 3: Edit `SwipeDeckView.swift`**

3a. `Leaving` gets the emojis it was filed under:

```swift
private struct Leaving: Identifiable {
    let id = UUID()
    let assetID: String
    let decision: Decision
    let from: CGSize
    /// Emojis of the albums a kept photo went into, for its stamp.
    var filing = ""
}
```

3b. New state in `SwipeDeckView` (beside the others):

```swift
    @State private var selectedAlbums: Set<String> = []
    @State private var ledger = FilingLedger()
    @State private var editor: EditorTarget?
```

3c. `init`: `_session = State(initialValue: ReviewSession(ids: deck.ids, state: state, onlyUndecided: !deck.everyPhoto))`

3d. In `body`, wrap the card `ZStack { ... }.frame(maxWidth: .infinity, maxHeight: .infinity)` in an HStack with the rail:

```swift
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    // ...existing finished / cards / leaving content unchanged...
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                AlbumRail(selected: $selectedAlbums, onAdd: { editor = .new }, onEdit: { editor = .edit($0) })
                    .opacity(session.isFinished ? 0 : 1)
                    .allowsHitTesting(!session.isFinished)
            }
```

Pass the emojis to the top card: `CardView(id: id, drag: isTop ? drag : .zero, filing: isTop ? filingEmojis : "")`.

3e. Modifiers on the outer `VStack`, after `.sheet(isPresented: $showTrash)`:

```swift
        .sheet(item: $editor) { target in
            AlbumEditor(editing: target.album) { newID in
                withAnimation(.spring(duration: 0.3)) { _ = selectedAlbums.insert(newID) }
            }
        }
        .onChange(of: model.state.shelf.map(\.id)) { _, ids in
            selectedAlbums.formIntersection(ids)
        }
        .overlay(alignment: .top) {
            if let message = model.albumError {
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 56)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.5))
                        withAnimation { model.albumError = nil }
                    }
            }
        }
        .animation(.spring(duration: 0.35), value: model.albumError)
```

3f. Helper next to `isBookmarked`:

```swift
    /// Emojis of the selected albums, in rail order.
    private var filingEmojis: String {
        model.state.shelf.filter { selectedAlbums.contains($0.id) }.map(\.emoji).joined()
    }
```

3g. `decide(_:)`: file the photo before the swipe is recorded. Replace the first lines up to `leaving.append(exit)` with:

```swift
        guard let id = session.current, !isUndoing else { return }
        Haptics.tap(model.hapticsEnabled)
        var filed: [String] = []
        if decision == .keep {
            let members = Dictionary(uniqueKeysWithValues: selectedAlbums.map { ($0, Set(model.albumMembers[$0] ?? [])) })
            filed = FilingLedger.newAlbums(for: id, selected: selectedAlbums,
                                           shelfOrder: model.state.shelf.map(\.id), members: members)
            model.file(id, into: filed)
        }
        ledger.record(id, albums: filed)
        let exit = Leaving(assetID: id, decision: decision, from: drag,
                           filing: decision == .keep ? filingEmojis : "")
        leaving.append(exit)
```

(Rest of `decide` unchanged.)

3h. `undo()`: take the photo back out. After the existing `let wasKept = ...` line add:

```swift
        let photo = session.ids[session.index - 1]
        model.unfile(photo, from: ledger.takeBack(photo))
```

3i. `FlyingCard` passes the emojis: `CardView(id: item.assetID, drag: CGSize(width: side * 200, height: 0), filing: item.filing)`.

3j. `CardView` gets `var filing = ""` and its keep stamp shows the emojis:

```swift
            .overlay(alignment: .topLeading) { stamp(filing.isEmpty ? "Keep" : "Keep \(filing)", "checkmark", Theme.keep, drag.width) }
```

- [ ] **Step 4: Type-check and build for the simulator**

Run: `swift build && xcodebuild -project PhotoSwipe.xcodeproj -scheme PhotoSwipe -destination "generic/platform=iOS Simulator" -derivedDataPath build CODE_SIGNING_ALLOWED=NO build`
Expected: both succeed.

- [ ] **Step 5: Commit and push**

```bash
git add Sources/PhotoSwipeUI
git commit -m "Swipe screen: emoji album rail, file on keep, undo takes it back out"
git push origin main
```

---

### Task 5: Albums on the home screen + the album page

**Files:**
- Create: `Sources/PhotoSwipeUI/AlbumsViews.swift`
- Modify: `Sources/PhotoSwipeUI/HomeView.swift`

**Interfaces:**
- Consumes: Tasks 2 to 4.
- Produces: `AlbumsSection(onOpen: (ShelfAlbum) -> Void, onNew: () -> Void)`, `AlbumView(shelfID: String)`.

- [ ] **Step 1: Create `Sources/PhotoSwipeUI/AlbumsViews.swift`**

```swift
import SwiftUI
import SwipeCore

/// The emoji albums on the home screen: cover photo, name, how many photos. Then ＋ New album.
struct AlbumsSection: View {
    let onOpen: (ShelfAlbum) -> Void
    let onNew: () -> Void
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Albums").eyebrow()
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
            ForEach(model.state.shelf) { album in
                Button { onOpen(album) } label: { row(album) }
                    .buttonStyle(DimStyle())
                    .transition(.opacity)
                Rectangle().fill(Theme.hairline).frame(height: 1).padding(.leading, 92)
            }
            Button(action: onNew) { newRow }
                .buttonStyle(DimStyle())
        }
        .animation(.spring(duration: 0.4), value: model.state.shelf.map(\.id))
    }

    private func row(_ album: ShelfAlbum) -> some View {
        let count = model.albumMembers[album.id]?.count ?? 0
        return HStack(spacing: 14) {
            Group {
                if let cover = model.albumMembers[album.id]?.first {
                    Tile(id: cover, side: 200)
                } else {
                    Theme.card.overlay { Text(album.emoji).font(.title2) }
                }
            }
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(album.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(count == 1 ? "1 photo" : "\(count) photos")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(Theme.muted)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: count)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var newRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "plus")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 58, height: 58)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Theme.ink.opacity(0.3), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                }
            VStack(alignment: .leading, spacing: 3) {
                Text("New album").font(.body.weight(.medium)).foregroundStyle(Theme.ink)
                if model.state.shelf.isEmpty {
                    Text("Or tap ＋ while swiping to sort photos as you go.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

/// One emoji album, edge to edge, newest first. Swipe runs the deck on every photo in it.
struct AlbumView: View {
    let shelfID: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var deck: Deck?
    @State private var editor: EditorTarget?

    var body: some View {
        let album = model.state.shelf.first { $0.id == shelfID }
        let title = album?.title ?? "Album"
        let ids = (model.albumMembers[shelfID] ?? []).filter { model.library.ref($0) != nil }
        ScrollView {
            if ids.isEmpty {
                ContentUnavailableView("No photos yet", systemImage: "photo.on.rectangle",
                                       description: Text("Select \(album?.emoji ?? "it") on the swipe screen, then swipe right."))
                    .padding(.top, 60)
            } else {
                Text(ids.count == 1 ? "1 photo" : "\(ids.count) photos")
                    .eyebrow()
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                LazyVGrid(columns: thumbColumns, spacing: 2) {
                    ForEach(ids, id: \.self) { id in
                        Thumb(id: id)
                            .onTapGesture {
                                deck = Deck(title: title, ids: Array(ids.drop { $0 != id }), everyPhoto: true)
                            }
                            .contextMenu {
                                Button("Remove from album", systemImage: "rectangle.stack.badge.minus") {
                                    withAnimation(.spring(duration: 0.35)) { model.unfile(id, from: [shelfID]) }
                                }
                            }
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                }
            }
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle(title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Swipe") { deck = Deck(title: title, ids: ids, everyPhoto: true) }
                    .disabled(ids.isEmpty)
                Menu {
                    if let album { Button("Edit", systemImage: "pencil") { editor = .edit(album) } }
                    Button("Open Photos", systemImage: "photo.on.rectangle") { openPhotosApp() }
                    Button("Remove from rail", systemImage: "minus.circle") {
                        model.removeFromShelf(shelfID)
                        dismiss()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("More")
            }
        }
        .task { await model.refreshAlbums() }
        .sheet(item: $editor) { target in AlbumEditor(editing: target.album) }
        .cover(item: $deck) { deck in
            SwipeDeckView(deck: deck, state: model.state)
        }
    }
}
```

- [ ] **Step 2: Wire it into `HomeView.swift`**

`Route` gets a case: `case bookmarks, stats, settings` → add a new line `case album(String)`.

New state: `@State private var editor: EditorTarget?`

In the `LazyVStack`, right after the `trashRow` block and before `onThisDay`:

```swift
                    AlbumsSection(onOpen: { route = .album($0.id) }, onNew: { editor = .new })
                        .padding(.top, 28)
                        .rise(ready, order: 1)
```

In `.navigationDestination(item: $route)` add: `case .album(let id): AlbumView(shelfID: id)`

After `.sheet(isPresented: $showTrash)` add: `.sheet(item: $editor) { target in AlbumEditor(editing: target.album) }`

- [ ] **Step 3: Type-check and build for the simulator** (same two commands as Task 4 Step 4). Expected: both succeed.

- [ ] **Step 4: Commit and push**

```bash
git add Sources/PhotoSwipeUI
git commit -m "Home: Albums list and album page (swipe an album, remove from album)"
git push origin main
```

---

### Task 6: Check it on the simulator, ship v1.1.0

**Files:**
- Modify: `PhotoSwipe.xcodeproj/project.pbxproj` (version, photo permission text)
- Modify: `README.md`, `CLAUDE.md`, `docs/spec.md`, `SESSION_HANDOFF.md`, `site/index.html`

- [ ] **Step 1: Run on the iPhone simulator** (it already has real test photos). Boot it, install the build from `build/Build/Products/Debug-iphonesimulator/PhotoSwipe.app`, launch with `xcrun simctl launch booted <bundle id>` (bundle id: `grep PRODUCT_BUNDLE_IDENTIFIER PhotoSwipe.xcodeproj/project.pbxproj`). Check each of these and take a screenshot of each (`xcrun simctl io booted screenshot <file>` into the scratchpad, never into the repo):
  1. First launch: rail shows only ＋; home Albums shows only "＋ New album".
  2. ＋ → emoji keyboard opens → pick ⛳, type Golf → Create → ⛳ springs onto the rail, selected (green ring).
  3. Tap ⛳: "Golf" bubble slides out and fades; tap again toggles off.
  4. Drag right with ⛳ on: stamp reads "Keep ⛳"; release; next photo, ⛳ still selected.
  5. Open the simulator Photos app → Albums → "⛳ Golf" holds those photos.
  6. Swipe right, then Undo at once: the photo is gone from "⛳ Golf" in Photos.
  7. Delete "⛳ Golf" in the Photos app, swipe right with ⛳ on → album comes back with the photo.
  8. Home → Albums row shows cover + count; open it, Swipe runs every photo in it; long-press → Remove from album works.
  9. Make 12 albums: rail scrolls and ＋ is still reachable.
  10. Settings → Reset progress: albums still there.

  Fix anything that fails before going on. Delete the screenshots after (CLAUDE.md §10.6 style).

- [ ] **Step 2: Version and permission text** in `PhotoSwipe.xcodeproj/project.pbxproj` (both Debug and Release blocks):

```bash
sed -i '' 's/MARKETING_VERSION = 1.0.0;/MARKETING_VERSION = 1.1.0;/; s/CURRENT_PROJECT_VERSION = 1;/CURRENT_PROJECT_VERSION = 2;/' PhotoSwipe.xcodeproj/project.pbxproj
sed -i '' 's/so you can choose which to keep and which to delete\. Nothing leaves your phone\./so you can choose which to keep, which to delete and which albums they go in. Nothing leaves your phone./' PhotoSwipe.xcodeproj/project.pbxproj
grep -n "MARKETING_VERSION\|CURRENT_PROJECT_VERSION\|NSPhotoLibraryUsageDescription" PhotoSwipe.xcodeproj/project.pbxproj
```

Expected: 1.1.0 and 2 on two lines each; new permission text on two lines.

- [ ] **Step 3: Docs.**
  - `README.md` "What it does": one short line about emoji albums (tap an emoji on the right, swipe right, it lands in that album in Photos; shared iCloud albums are not possible).
  - `CLAUDE.md` invariants: add "Album code only adds/removes album membership, never deletes a photo. The rail starts empty; Reset progress keeps albums."
  - `docs/spec.md`: add the emoji albums feature.
  - `site/index.html`: next to the bookmark sentence (around line 171), add one sentence about emoji albums. Outbound links need `target="_blank" rel="noopener"`. Deploy with `cd site && vercel deploy --prod --yes --scope warrenlimzf-projects`, then check https://www.warrenlimzf.com/photo-swipe/.

- [ ] **Step 4: Tests, build, commit, push, release**

```bash
./test.sh
xcodebuild -project PhotoSwipe.xcodeproj -scheme PhotoSwipe -destination "generic/platform=iOS Simulator" -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
git add -A && git commit -m "v1.1.0: emoji albums" && git push origin main
gh release create v1.1.0 --title "v1.1.0: emoji albums" --notes "Sort photos into albums while you swipe. Tap ＋ on the right of the swipe screen to make an emoji album (it becomes a real album in Photos), tap the emoji, swipe right, and the photo goes straight in. Your albums are listed on the home screen; open one to swipe through it again. Undo takes a photo back out. To update: pull, open in Xcode, press Run."
```

Never push the `dev-history-2026-10-14` branch to `origin`.

- [ ] **Step 5: Put it on Warren's phone.** Ask Warren to plug in and unlock the iPhone, then run `./install-local.sh` (gitignored; holds his Team ID). If a Keychain box asks, he types his Mac password and picks Always Allow.

- [ ] **Step 6: Wrap up.** Add a 3–6 line entry for any bug fixed along the way to `SESSION_HANDOFF.md` (debug journal), then run the `session-handoff` skill.
