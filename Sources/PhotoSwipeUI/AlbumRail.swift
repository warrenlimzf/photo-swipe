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
