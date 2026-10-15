import SwiftUI
import SwipeCore

/// The emoji albums on the home screen: a sideways row of white cards (emoji, name, count),
/// ending in a ＋ card.
struct AlbumsSection: View {
    let onOpen: (ShelfAlbum) -> Void
    let onNew: () -> Void
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Albums").sectionTitle()
                Spacer()
                if !model.state.shelf.isEmpty {
                    Text("\(model.state.shelf.count)").font(.numeral(15, weight: .semibold)).foregroundStyle(Theme.dim)
                }
            }
            .padding(.horizontal, 22)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.state.shelf) { album in
                        Button { onOpen(album) } label: { card(album) }
                            .buttonStyle(PressStyle())
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                    Button(action: onNew) { newCard }
                        .buttonStyle(PressStyle())
                        .accessibilityLabel("New album")
                }
                .padding(.vertical, 12)
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .padding(.vertical, -12)
        }
        .animation(.spring(duration: 0.4), value: model.state.shelf.map(\.id))
    }

    private func card(_ album: ShelfAlbum) -> some View {
        let count = model.albumMembers[album.id]?.count ?? 0
        return VStack(alignment: .leading, spacing: 10) {
            Text(album.emoji)
                .font(.system(size: 30))
                .frame(width: 52, height: 52)
                .background(Theme.b100, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("\(count)")
                    .font(.numeral(15, weight: .medium))
                    .foregroundStyle(Theme.dim)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: count)
            }
        }
        .frame(width: 108, alignment: .leading)
        .padding(14)
        .card(26)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(album.name), \(count) photos")
    }

    private var newCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Theme.cta, in: Circle())
                .shadow(color: Theme.b500.opacity(0.35), radius: 8, y: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text("New").font(.system(.body, design: .rounded, weight: .semibold)).foregroundStyle(Theme.ink)
                Text("album").font(.subheadline).foregroundStyle(Theme.dim)
            }
        }
        .frame(width: 108, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Theme.b500.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        }
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
        let counter = selecting ? (picked.isEmpty ? "Tap to select" : "\(picked.count) selected")
                                : (ids.count == 1 ? "1 photo" : "\(ids.count) photos")
        HeroScreen(title: title, subtitle: counter) {
            if ids.isEmpty {
                ContentUnavailableView("No photos yet", systemImage: "photo.on.rectangle",
                                       description: Text("Pick \(album?.emoji ?? "it") while swiping, then swipe right."))
                    .foregroundStyle(Theme.dim, Theme.ink)
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: thumbColumns, spacing: 4) {
                    ForEach(ids, id: \.self) { id in
                        Thumb(id: id)
                            .overlay(alignment: .bottomLeading) {
                                if model.library.favorites.contains(id) {
                                    Image(systemName: "heart.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .shadow(radius: 3)
                                        .padding(8)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .overlay {
                                if selecting && picked.contains(id) {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Theme.b500, lineWidth: 3)
                                        .background(Theme.b500.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                            .overlay(alignment: .bottomTrailing) {
                                if selecting { SelectMark(on: picked.contains(id)).padding(7) }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selecting {
                                    Haptics.tick(model.hapticsEnabled)
                                    withAnimation(.snappy(duration: 0.2)) { toggle(id) }
                                } else {
                                    Haptics.press()
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
                .padding(.horizontal, 16)
                .animation(.spring(duration: 0.35), value: ids)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if selecting {
                actionBar(ids: ids)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: selecting)
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
            ActionItem(icon: allFavourite ? "heart.slash" : "heart", label: allFavourite ? "Unfavourite" : "Favourite", tint: Theme.b700) {
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
                ActionLabel(icon: "arrow.right.circle", label: "Move to", tint: Theme.b700)
            }
            .disabled(others.isEmpty)
            .frame(maxWidth: .infinity)
            ActionItem(icon: "rectangle.stack.badge.minus", label: "Remove", tint: Theme.b700) {
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
        .card(26)
        .shadow(color: Theme.ink.opacity(0.08), radius: 20, y: 6)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

private struct SelectMark: View {
    let on: Bool

    var body: some View {
        ZStack {
            Circle().fill(on ? AnyShapeStyle(Theme.cta) : AnyShapeStyle(Color.black.opacity(0.3)))
            Circle().strokeBorder(.white, lineWidth: 1.5)
            if on {
                Image(systemName: "checkmark").font(.caption2.weight(.heavy)).foregroundStyle(.white)
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
            Image(systemName: icon).font(.title3.weight(.semibold))
            Text(label).font(.system(.caption, design: .rounded, weight: .semibold))
        }
        .foregroundStyle(tint)
        .frame(minHeight: 44)
    }
}
