import SwiftUI
import SwipeCore

/// The emoji albums in a row under the photo on the swipe screen. Tap one to pick it (tapping
/// another switches; tapping it again turns it off), hold and drag to reorder, ＋ to add.
struct AlbumRail: View {
    @Binding var selected: Set<String>
    let onAdd: () -> Void
    let onEdit: (ShelfAlbum) -> Void
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bubble: String?
    @State private var bubbleTask: Task<Void, Never>?
    @State private var dragging: String?

    var body: some View {
        // One row, centred while it fits, scrolling sideways once it doesn't.
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.state.shelf) { album in
                        emojiButton(album)
                            .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
                    }
                    addButton
                }
                // Catches a drop that lands between emojis, so the drag always ends cleanly.
                .onDrop(of: [.text], isTargeted: nil) { _ in dragging = nil; return true }
                .padding(.horizontal, 6)
                .frame(minWidth: geo.size.width)
                .frame(height: geo.size.height)
                .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.3), value: model.state.shelf.map(\.id))
            }
            .scrollBounceBehavior(.basedOnSize)
            // The name bubble rises above the row, so clipping is off; the mask then
            // clips left and right only.
            .scrollClipDisabled()
            .mask { Rectangle().padding(.vertical, -80) }
        }
        .frame(height: 54)
    }

    private func emojiButton(_ album: ShelfAlbum) -> some View {
        let isOn = selected.contains(album.id)
        return Button { toggle(album) } label: {
            Text(album.emoji)
                .font(.system(size: 24))
                .frame(width: 46, height: 46)
                .background(.ultraThinMaterial, in: Circle())
                .background { if isOn { Circle().fill(Theme.keep.opacity(0.25)).shadow(color: Theme.keep.opacity(0.6), radius: 10) } }
                .overlay { Circle().strokeBorder(isOn ? Theme.keep : Theme.hairline, lineWidth: isOn ? 2.5 : 1) }
                .scaleEffect(isOn && !reduceMotion ? 1.06 : 1)
                .opacity(selected.isEmpty || isOn ? 1 : 0.7)
        }
        .buttonStyle(PressStyle())
        .overlay(alignment: .top) {
            if bubble == album.id {
                NameBubble(name: album.name, isOn: isOn)
                    .offset(y: -46)
                    .transition(reduceMotion ? .opacity : .offset(y: 12).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .zIndex(bubble == album.id ? 1 : 0)
        .opacity(dragging == album.id ? 0.35 : 1)
        // Hold and drag to move an emoji along the rail. The rest slide out of its way.
        .onDrag {
            dragging = album.id
            return NSItemProvider(object: album.id as NSString)
        } preview: {
            Text(album.emoji)
                .font(.system(size: 24))
                .frame(width: 46, height: 46)
                .background(.ultraThinMaterial, in: Circle())
                .contentShape(.dragPreview, Circle())
        }
        .onDrop(of: [.text], delegate: RailDrop(target: album.id, dragging: $dragging, model: model, reduceMotion: reduceMotion))
        .contextMenu {
            Button("Edit", systemImage: "pencil") { onEdit(album) }
            Button("Remove from rail", systemImage: "minus.circle") {
                selected.remove(album.id)
                model.removeFromShelf(album.id)
            }
        }
        .accessibilityLabel("\(album.name) album")
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityHint("When selected, every photo you keep moves into this album")
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
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.3, bounce: 0.35)) {
            // One album at a time: picking another switches to it.
            selected = selected.contains(album.id) ? [] : [album.id]
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

/// Reorders the rail live as a dragged emoji passes over another one.
private struct RailDrop: DropDelegate {
    let target: String
    @Binding var dragging: String?
    let model: AppModel
    let reduceMotion: Bool

    func dropEntered(info: DropInfo) {
        guard let moving = dragging, moving != target,
              let to = model.state.shelf.firstIndex(where: { $0.id == target }) else { return }
        Haptics.tick(model.hapticsEnabled)
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.3, bounce: 0.25)) {
            model.moveShelf(moving, to: to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
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
