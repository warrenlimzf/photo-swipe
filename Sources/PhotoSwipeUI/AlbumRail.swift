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
    /// The emoji being held, where it started, and the slot it would land in now.
    @State private var lifted: String?
    @State private var liftedFrom = 0
    @State private var landing = 0
    @State private var dragX: CGFloat = 0
    @State private var menuFor: ShelfAlbum?

    /// One emoji plus the gap after it.
    private let slot: CGFloat = 46 + 12
    private let addID = "rail-add"

    var body: some View {
        // One row, centred while it fits, scrolling sideways once it doesn't.
        GeometryReader { geo in
          ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(model.state.shelf.enumerated()), id: \.element.id) { index, album in
                        emojiButton(album, at: index)
                            .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
                    }
                    addButton.id(addID)
                }
                .padding(.horizontal, 6)
                .frame(minWidth: geo.size.width)
                .frame(height: geo.size.height)
                .animation(reduceMotion ? .easeOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.3), value: model.state.shelf.map(\.id))
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDisabled(lifted != nil)
            // The name bubble rises above the row, so clipping is off; the mask then
            // clips left and right only.
            .scrollClipDisabled()
            .mask { Rectangle().padding(.vertical, -80) }
            // A new album lands at the end of the row: bring it and ＋ into view.
            .onChange(of: model.state.shelf.count) { old, new in
                guard new > old else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) { proxy.scrollTo(addID, anchor: .trailing) }
            }
          }
        }
        .frame(height: 54)
        .confirmationDialog(menuFor?.title ?? "", isPresented: Binding(get: { menuFor != nil }, set: { if !$0 { menuFor = nil } }),
                            titleVisibility: .visible, presenting: menuFor) { album in
            Button("Edit") { onEdit(album) }
            Button("Remove from rail", role: .destructive) {
                selected.remove(album.id)
                model.removeFromShelf(album.id)
            }
        }
    }

    private func emojiButton(_ album: ShelfAlbum, at index: Int) -> some View {
        let isOn = selected.contains(album.id)
        let isLifted = lifted == album.id
        return Text(album.emoji)
            .font(.system(size: 24))
            .frame(width: 46, height: 46)
            .background(isOn ? Theme.b100 : .white, in: Circle())
            .shadow(color: isOn ? Theme.b500.opacity(0.45) : Theme.ink.opacity(0.08), radius: isOn ? 10 : 6, y: isOn ? 4 : 3)
            .overlay { Circle().strokeBorder(Theme.b500, lineWidth: isOn ? 2.5 : 0) }
            .scaleEffect(isLifted ? 1.22 : (isOn && !reduceMotion ? 1.06 : 1))
            .shadow(color: Theme.ink.opacity(isLifted ? 0.25 : 0), radius: 12, y: 8)
            .opacity(selected.isEmpty || isOn || isLifted ? 1 : 0.6)
            .contentShape(Circle())
            .overlay(alignment: .top) {
                if bubble == album.id {
                    NameBubble(name: album.name, isOn: isOn)
                        .offset(y: -46)
                        .transition(reduceMotion ? .opacity : .offset(y: 12).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            // The held emoji rides the finger with no animation; the others glide aside.
            .offset(x: isLifted ? dragX : shift(for: index))
            .zIndex(isLifted ? 2 : (bubble == album.id ? 1 : 0))
            .onTapGesture { toggle(album) }
            // A UIKit long press, not SwiftUI's LongPress.sequenced(before: Drag): that one claimed
            // every touch on an emoji, so the row could not scroll and ＋ sat off screen once the
            // rail outgrew the width (v1.7.2). A quick drag now scrolls; a 0.22 s hold lifts.
            .holdDrag(minimumDuration: 0.22,
                      began: { lift(album, at: index) },
                      changed: { move(album, by: $0) },
                      ended: { drop(album, after: $0) },
                      cancelled: { cancelLift(album) })
            .accessibilityElement()
            .accessibilityLabel("\(album.name) album")
            .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
            .accessibilityHint("When selected, every photo you keep moves into this album")
            .accessibilityAction { toggle(album) }
            .accessibilityAction(named: "Edit") { onEdit(album) }
            .accessibilityAction(named: "Remove from rail") {
                selected.remove(album.id)
                model.removeFromShelf(album.id)
            }
    }

    /// How far an emoji steps aside to open a gap where the held one would land.
    private func shift(for index: Int) -> CGFloat {
        guard lifted != nil else { return 0 }
        if liftedFrom < landing, index > liftedFrom, index <= landing { return -slot }
        if landing < liftedFrom, index >= landing, index < liftedFrom { return slot }
        return 0
    }

    /// Hold to lift, drag to move, let go to drop. A hold with no drag opens Edit / Remove.
    private func lift(_ album: ShelfAlbum, at index: Int) {
        Haptics.tap(model.hapticsEnabled)
        liftedFrom = index
        landing = index
        withAnimation(.spring(duration: 0.22, bounce: 0.35)) { lifted = album.id }
    }

    private func move(_ album: ShelfAlbum, by x: CGFloat) {
        guard lifted == album.id else { return }
        var still = Transaction()
        still.disablesAnimations = true
        withTransaction(still) { dragX = x }
        let count = model.state.shelf.count
        let spot = max(0, min(count - 1, liftedFrom + Int((x / slot).rounded())))
        if spot != landing {
            Haptics.tick(model.hapticsEnabled)
            withAnimation(reduceMotion ? .easeOut(duration: 0.12) : .spring(duration: 0.26, bounce: 0.2)) { landing = spot }
        }
    }

    private func drop(_ album: ShelfAlbum, after x: CGFloat) {
        guard lifted == album.id else { return }
        if abs(x) < 8 {
            withAnimation(.spring(duration: 0.22)) { lifted = nil; dragX = 0 }
            menuFor = album
            return
        }
        let from = liftedFrom, to = landing
        // Settle into the gap, then commit the new order in one frame so nothing jumps.
        withAnimation(.spring(duration: 0.26, bounce: 0.2)) {
            dragX = CGFloat(to - from) * slot
        } completion: {
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) {
                model.moveShelf(album.id, to: to)
                lifted = nil
                dragX = 0
                landing = 0
            }
        }
    }

    /// The system took the touch away mid-hold: put the emoji back where it was.
    private func cancelLift(_ album: ShelfAlbum) {
        guard lifted == album.id else { return }
        withAnimation(.spring(duration: 0.22)) { lifted = nil; dragX = 0; landing = 0 }
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Image(systemName: "plus")
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Theme.cta, in: Circle())
                .shadow(color: Theme.b500.opacity(0.35), radius: 8, y: 4)
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

/// The album's name, shown for a moment when its emoji is tapped.
private struct NameBubble: View {
    let name: String
    let isOn: Bool

    var body: some View {
        Label(name, systemImage: isOn ? "checkmark" : "xmark")
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOn ? AnyShapeStyle(Theme.cta) : AnyShapeStyle(Theme.ink), in: Capsule())
            .shadow(color: Theme.ink.opacity(0.15), radius: 8, y: 4)
            .fixedSize()
    }
}

#if os(iOS)
import UIKit

/// A long press that keeps reporting the finger's sideways travel until it lifts. Being a plain
/// UILongPressGestureRecognizer, it fails as soon as the finger moves before the hold, which
/// leaves the touch to the rail's scroll view.
private struct HoldDrag: UIGestureRecognizerRepresentable {
    let minimumDuration: Double
    let began: () -> Void
    let changed: (CGFloat) -> Void
    let ended: (CGFloat) -> Void
    let cancelled: () -> Void

    final class Coordinator { var startX: CGFloat = 0 }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let g = UILongPressGestureRecognizer()
        g.minimumPressDuration = minimumDuration
        return g
    }

    func handleUIGestureRecognizerAction(_ g: UILongPressGestureRecognizer, context: Context) {
        let x = g.location(in: nil).x
        switch g.state {
        case .began:
            context.coordinator.startX = x
            began()
        case .changed:
            changed(x - context.coordinator.startX)
        case .ended:
            ended(x - context.coordinator.startX)
        case .cancelled, .failed:
            cancelled()
        default:
            break
        }
    }
}

private extension View {
    func holdDrag(minimumDuration: Double, began: @escaping () -> Void, changed: @escaping (CGFloat) -> Void,
                  ended: @escaping (CGFloat) -> Void, cancelled: @escaping () -> Void) -> some View {
        gesture(HoldDrag(minimumDuration: minimumDuration, began: began, changed: changed, ended: ended, cancelled: cancelled))
    }
}
#else
// macOS only exists so `swift build` type-checks the screens.
private extension View {
    func holdDrag(minimumDuration: Double, began: @escaping () -> Void, changed: @escaping (CGFloat) -> Void,
                  ended: @escaping (CGFloat) -> Void, cancelled: @escaping () -> Void) -> some View {
        self
    }
}
#endif
