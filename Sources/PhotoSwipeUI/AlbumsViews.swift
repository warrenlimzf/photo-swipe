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
