import SwiftUI
import SwipeCore

/// The emoji albums on the home screen: the album's emoji, its name, how many photos. Then ＋ New album.
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
            Text(album.emoji)
                .font(.system(size: 40))
                .frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 3) {
                Text(album.name)
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

/// One emoji album, edge to edge, newest first. Swipe runs the deck on every photo in it;
/// Select picks photos to favourite, move, take out or delete in one go.
struct AlbumView: View {
    let shelfID: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var deck: Deck?
    @State private var editor: EditorTarget?
    @State private var selecting = false
    @State private var picked: Set<String> = []
    @State private var showTrash = false

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
                Text(selecting ? (picked.isEmpty ? "Tap photos to select" : "\(picked.count) selected")
                               : (ids.count == 1 ? "1 photo" : "\(ids.count) photos"))
                    .eyebrow()
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                LazyVGrid(columns: thumbColumns, spacing: 2) {
                    ForEach(ids, id: \.self) { id in
                        Thumb(id: id)
                            .overlay(alignment: .bottomLeading) {
                                if model.library.favorites.contains(id) {
                                    Image(systemName: "heart.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .shadow(radius: 3)
                                        .padding(6)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .overlay { if selecting && picked.contains(id) { Theme.keep.opacity(0.25) } }
                            .overlay(alignment: .bottomTrailing) {
                                if selecting { SelectMark(on: picked.contains(id)).padding(6) }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selecting {
                                    Haptics.tick(model.hapticsEnabled)
                                    withAnimation(.snappy(duration: 0.2)) { toggle(id) }
                                } else {
                                    deck = Deck(title: title, ids: Array(ids.drop { $0 != id }), everyPhoto: true)
                                }
                            }
                            .contextMenu {
                                if !selecting {
                                    Button("Remove from album", systemImage: "rectangle.stack.badge.minus") {
                                        withAnimation(.spring(duration: 0.35)) { model.unfile(id, from: [shelfID]) }
                                    }
                                }
                            }
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.35), value: ids)
            }
        }
        .background(Theme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if selecting {
                actionBar(ids: ids)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: selecting)
        .navigationTitle(title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if selecting {
                    Button(picked.count == ids.count ? "None" : "All") {
                        withAnimation(.snappy(duration: 0.2)) {
                            picked = picked.count == ids.count ? [] : Set(ids)
                        }
                    }
                    Button("Done") { withAnimation { selecting = false; picked = [] } }
                        .fontWeight(.semibold)
                } else {
                    Button("Select") { withAnimation { selecting = true } }
                        .disabled(ids.isEmpty)
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
        }
        .task { await model.refreshAlbums() }
        .sheet(item: $editor) { target in AlbumEditor(editing: target.album) }
        .sheet(isPresented: $showTrash) { ReviewDeleteView() }
        .cover(item: $deck) { deck in
            SwipeDeckView(deck: deck, state: model.state)
        }
    }

    private func toggle(_ id: String) {
        if picked.contains(id) { picked.remove(id) } else { picked.insert(id) }
    }

    /// Favourite, Move to, Remove, Delete: one row, evenly spaced.
    private func actionBar(ids: [String]) -> some View {
        let chosen = ids.filter(picked.contains)
        let allFavourite = !chosen.isEmpty && chosen.allSatisfy(model.library.favorites.contains)
        let others = model.state.shelf.filter { $0.id != shelfID }
        return HStack(spacing: 0) {
            ActionItem(icon: allFavourite ? "heart.slash" : "heart", label: allFavourite ? "Unfavourite" : "Favourite", tint: Theme.ink) {
                withAnimation(.spring(duration: 0.3)) { model.setFavorite(chosen, to: !allFavourite) }
                Haptics.success(model.hapticsEnabled)
            }
            Menu {
                ForEach(others) { target in
                    Button(target.title) {
                        withAnimation(.spring(duration: 0.35)) { model.move(chosen, from: shelfID, to: target.id) }
                        Haptics.success(model.hapticsEnabled)
                        picked = []
                    }
                }
            } label: {
                ActionLabel(icon: "arrow.right.circle", label: "Move to", tint: Theme.ink)
            }
            .disabled(others.isEmpty)
            .frame(maxWidth: .infinity)
            ActionItem(icon: "rectangle.stack.badge.minus", label: "Remove", tint: Theme.ink) {
                withAnimation(.spring(duration: 0.35)) { for id in chosen { model.unfile(id, from: [shelfID]) } }
                picked = []
            }
            ActionItem(icon: "trash", label: "Delete", tint: Theme.delete) {
                // Deleting still goes through the review grid and Apple's own confirmation.
                model.markForDeletion(chosen)
                picked = []
                showTrash = true
            }
        }
        .disabled(chosen.isEmpty)
        .opacity(chosen.isEmpty ? 0.45 : 1)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

private struct SelectMark: View {
    let on: Bool

    var body: some View {
        ZStack {
            Circle().fill(on ? Theme.keep : .black.opacity(0.3))
            Circle().strokeBorder(.white, lineWidth: 1.5)
            if on {
                Image(systemName: "checkmark").font(.caption2.weight(.heavy)).foregroundStyle(Theme.canvas)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 24, height: 24)
        .animation(.spring(duration: 0.25, bounce: 0.4), value: on)
    }
}

private struct ActionItem: View {
    let icon: String
    let label: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) { ActionLabel(icon: icon, label: label, tint: tint) }
            .buttonStyle(PressStyle())
            .frame(maxWidth: .infinity)
    }
}

private struct ActionLabel: View {
    let icon: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.title3)
            Text(label).font(.caption.weight(.medium))
        }
        .foregroundStyle(tint)
        .frame(minHeight: 44)
    }
}
