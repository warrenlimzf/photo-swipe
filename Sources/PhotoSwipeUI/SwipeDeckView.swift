import AVKit
import SwiftUI
import SwipeCore

/// Pixel size the swipe cards load their photos at.
private let cardSide: CGFloat = 1600

/// A card that has been decided and is on its way off screen.
private struct Leaving: Identifiable {
    let id = UUID()
    let assetID: String
    let decision: Decision
    let from: CGSize
    /// Emojis of the albums a kept photo went into, for its stamp.
    var filing = ""
}

/// The swipe screen. Lit by a blur of the photo in front of you.
struct SwipeDeckView: View {
    let deck: Deck
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session: ReviewSession
    @State private var drag: CGSize = .zero
    @State private var leaving: [Leaving] = []
    @State private var isUndoing = false
    @State private var pastThreshold = false
    @State private var showTrash = false
    @State private var showInfo = false
    @State private var sizes: [String: Int64] = [:]
    @State private var selectedAlbums: Set<String> = []
    @State private var ledger = FilingLedger()
    @State private var editor: EditorTarget?

    private let threshold: CGFloat = 100

    init(deck: Deck, state: ReviewState) {
        self.deck = deck
        _session = State(initialValue: ReviewSession(ids: deck.ids, state: state, onlyUndecided: !deck.everyPhoto))
    }

    var body: some View {
        VStack(spacing: 12) {
            topBar
            ProgressLine(value: Double(session.index) / Double(max(session.ids.count, 1)), height: 2)
                .padding(.horizontal, 4)
            HStack(alignment: .top, spacing: 8) {
            ZStack {
                if session.isFinished {
                    finished.transition(.scale(scale: 0.96).combined(with: .opacity))
                }
                // Keyed by photo, so the card underneath becomes the top card without being rebuilt.
                ForEach([session.next, session.current].compactMap { $0 }, id: \.self) { id in
                    let isTop = id == session.current
                    CardView(id: id, drag: isTop ? drag : .zero, filing: isTop ? filingEmojis : "")
                        .scaleEffect(isTop ? 1 : 0.92 + 0.08 * pull)
                        .opacity(isTop ? 1 : Double(pull))
                        .offset(isTop ? drag : .zero)
                        .rotationEffect(.degrees(isTop && !reduceMotion ? Double(drag.width) / 24 : 0), anchor: .bottom)
                        .gesture(isTop ? dragGesture : nil)
                        .zIndex(isTop ? 1 : 0)
                        .transition(.identity)
                }
                // Decided cards finish their exit here, so the next photo is ready to swipe at once.
                ForEach(leaving) { item in
                    FlyingCard(item: item, reduceMotion: reduceMotion)
                        .zIndex(2)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
                AlbumRail(selected: $selectedAlbums, onAdd: { editor = .new }, onEdit: { editor = .edit($0) })
                    .opacity(session.isFinished ? 0 : 1)
                    .allowsHitTesting(!session.isFinished)
            }
            caption
            controls
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background { Ambient(id: session.current).equatable() }
        .sheet(isPresented: $showTrash) { ReviewDeleteView() }
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
        // Fresh album contents before the first swipe, so undo never takes a photo out of an
        // album it was already in.
        .task { await model.refreshAlbums() }
        .task(id: session.index) {
            let ahead = session.ids.dropFirst(session.index + 1).prefix(3)
            model.library.preheat(Array(ahead), side: cardSide)
        }
        .task(id: "\(showInfo)-\(session.index)") {
            guard showInfo, let id = session.current, sizes[id] == nil else { return }
            sizes[id] = await model.library.totalSize(of: [id])
        }
    }

    /// 0 at rest, 1 once the card is dragged far enough to count.
    private var pull: CGFloat { min(abs(drag.width) / threshold, 1) }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(PressStyle())
            .accessibilityLabel("Close")
            Spacer()
            VStack(spacing: 4) {
                Text(deck.title)
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                    .textCase(.uppercase)
                Text("\(min(session.index + 1, session.ids.count)) / \(session.ids.count)")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(Theme.muted)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: session.index)
            }
            Spacer()
            Button { showTrash = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .symbolEffect(.bounce, value: model.state.pendingDeletes.count)
                    Text("\(model.state.pendingDeletes.count)")
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: model.state.pendingDeletes.count)
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .frame(minWidth: 44, minHeight: 44)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(PressStyle())
            .disabled(model.state.pendingDeletes.isEmpty)
            .accessibilityLabel("\(model.state.pendingDeletes.count) to delete")
        }
        .foregroundStyle(Theme.ink)
    }

    /// When the photo was taken, under the photo rather than on it.
    private var caption: some View {
        VStack(spacing: 3) {
            if let id = session.current, let ref = model.library.ref(id) {
                Text(ref.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                if showInfo {
                    Text(details(ref, size: sizes[id]))
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                        .transition(.opacity)
                }
            }
        }
        .monospacedDigit()
        .frame(height: 44)
        .animation(.easeOut(duration: 0.2), value: session.index)
    }

    private func details(_ ref: AssetRef, size: Int64?) -> String {
        var parts = ["\(ref.pixelWidth) × \(ref.pixelHeight)"]
        if let size, size > 0 { parts.append(byteFormatter.string(fromByteCount: size)) }
        if ref.isVideo { parts.append(Duration.seconds(ref.duration).formatted(.time(pattern: .minuteSecond))) }
        return parts.joined(separator: " · ")
    }

    private var controls: some View {
        HStack(spacing: 16) {
            RoundButton(icon: "xmark", ring: Theme.delete, large: true) { decide(.delete) }
                .disabled(session.isFinished)
                .accessibilityLabel("Delete")
            RoundButton(icon: "arrow.uturn.backward") { undo() }
                .disabled(!canUndo)
                .accessibilityLabel("Undo")
            RoundButton(icon: showInfo ? "info.circle.fill" : "info.circle") {
                withAnimation(.easeOut(duration: 0.2)) { showInfo.toggle() }
            }
            .disabled(session.isFinished)
            .accessibilityLabel("Photo details")
            RoundButton(icon: isBookmarked ? "bookmark.fill" : "bookmark") { toggleBookmark() }
                .disabled(session.isFinished)
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark")
            RoundButton(icon: "checkmark", ring: Theme.keep, large: true) { decide(.keep) }
                .disabled(session.isFinished)
                .accessibilityLabel("Keep")
        }
    }

    private var finished: some View {
        let kept = session.ids.filter { model.state.decisions[$0] == .keep }.count
        let marked = session.ids.filter { model.state.decisions[$0] == .delete }.count
        return VStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Theme.canvas)
                .frame(width: 72, height: 72)
                .background(Theme.keep, in: Circle())
                .symbolEffect(.bounce, value: session.isFinished)
                .padding(.bottom, 6)
            Text("All sorted")
                .font(.largeTitle.bold())
            Text(marked == 0 ? "\(kept) kept" : "\(kept) kept, \(marked) to delete")
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(Theme.muted)
            VStack(spacing: 8) {
                if model.state.pendingDeletes.isEmpty {
                    PrimaryButton(title: "Back to library") { dismiss() }
                } else {
                    PrimaryButton(title: "Review \(model.state.pendingDeletes.count) to delete", color: Theme.delete) {
                        showTrash = true
                    }
                    Button("Later") { dismiss() }
                        .font(.body.weight(.medium))
                        .frame(minHeight: 44)
                }
            }
            .padding(.top, 14)
        }
        .foregroundStyle(Theme.ink)
        .padding(28)
    }

    /// A photo that has since been deleted for real cannot be brought back by undo.
    private var canUndo: Bool {
        session.canUndo && model.library.ref(session.ids[session.index - 1]) != nil
    }

    /// Emojis of the selected albums, in rail order.
    private var filingEmojis: String {
        model.state.shelf.filter { selectedAlbums.contains($0.id) }.map(\.emoji).joined()
    }

    private var isBookmarked: Bool {
        session.current.map(model.state.bookmarks.contains) ?? false
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isUndoing else { return }
                drag = CGSize(width: value.translation.width, height: value.translation.height * 0.3)
                let past = abs(drag.width) > threshold
                if past != pastThreshold {
                    pastThreshold = past
                    Haptics.tick(model.hapticsEnabled)
                }
            }
            .onEnded { value in
                pastThreshold = false
                // A quick flick counts even if the card has not travelled far.
                let reach = value.translation.width + (value.predictedEndTranslation.width - value.translation.width) * 0.3
                if reach > threshold {
                    decide(.keep)
                } else if reach < -threshold {
                    decide(.delete)
                } else {
                    withAnimation(.spring(duration: 0.4, bounce: 0.3)) { drag = .zero }
                }
            }
    }

    /// Records the verdict straight away. The old card flies off on its own while the next one
    /// rises into place, so there is never a wait between swipes.
    private func decide(_ decision: Decision) {
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
        withAnimation(.spring(duration: 0.34, bounce: 0.18)) {
            model.apply { session.swipe(decision, state: &$0, day: model.today) }
            drag = .zero
        }
        if session.isFinished { Haptics.success(model.hapticsEnabled) }
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            leaving.removeAll { $0.id == exit.id }
        }
    }

    /// Brings the last card back in from the side it left.
    private func undo() {
        guard !isUndoing, canUndo else { return }
        isUndoing = true
        Haptics.tap(model.hapticsEnabled)
        let wasKept = model.state.decisions[session.ids[session.index - 1]] == .keep
        let photo = session.ids[session.index - 1]
        model.unfile(photo, from: ledger.takeBack(photo))
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            model.apply { session.undo(state: &$0) }
            drag = CGSize(width: wasKept ? 620 : -620, height: 30)
        }
        Task {
            try? await Task.sleep(for: .milliseconds(20))
            withAnimation(.spring(duration: 0.42, bounce: 0.22)) {
                drag = .zero
            } completion: {
                isUndoing = false
            }
        }
    }

    private func toggleBookmark() {
        guard let id = session.current else { return }
        Haptics.tap(model.hapticsEnabled)
        model.apply { $0.toggleBookmark(id) }
    }
}

/// The room's colour. Its own view so dragging a card never redraws the blur.
private struct Ambient: View, Equatable {
    let id: String?

    var body: some View {
        ZStack {
            Theme.canvas
            if let id {
                Color.clear
                    .overlay { AssetImage(id: id, side: 300, fill: true, placeholder: false).blur(radius: 60) }
                    .clipped()
                    .opacity(0.38)
                    .id(id)
                    .transition(.opacity)
            }
            LinearGradient(colors: [Theme.canvas.opacity(0.7), Theme.canvas.opacity(0.2), Theme.canvas.opacity(0.85)],
                           startPoint: .top, endPoint: .bottom)
        }
        .animation(.easeInOut(duration: 0.6), value: id)
        .ignoresSafeArea()
    }
}

private struct FlyingCard: View {
    let item: Leaving
    let reduceMotion: Bool
    @State private var gone = false

    var body: some View {
        let side: CGFloat = item.decision == .keep ? 1 : -1
        let x = gone ? side * 640 : item.from.width
        CardView(id: item.assetID, drag: CGSize(width: side * 200, height: 0), filing: item.filing)
            .offset(x: x, y: item.from.height + (gone ? 40 : 0))
            .rotationEffect(.degrees(reduceMotion ? 0 : Double(x) / 24), anchor: .bottom)
            .opacity(reduceMotion && gone ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.32)) { gone = true }
            }
    }
}

private struct RoundButton: View {
    let icon: String
    var ring: Color?
    var large = false
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(large ? .title2.weight(.semibold) : .body.weight(.medium))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(ring ?? Theme.ink)
                .frame(width: large ? 68 : 48, height: large ? 68 : 48)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    if let ring { Circle().strokeBorder(ring.opacity(0.55), lineWidth: 1.5) }
                }
        }
        .buttonStyle(PressStyle())
        .opacity(isEnabled ? 1 : 0.3)
        .animation(.easeOut(duration: 0.2), value: isEnabled)
    }
}

/// The card is the photo: same shape, nothing around it.
private struct CardView: View {
    let id: String
    let drag: CGSize
    var filing = ""
    @Environment(AppModel.self) private var model
    @State private var player: AVPlayer?

    var body: some View {
        let ref = model.library.ref(id)
        let ratio = ref.map { CGFloat($0.pixelWidth) / CGFloat(max($0.pixelHeight, 1)) } ?? 0.75
        Theme.card
            .aspectRatio(ratio, contentMode: .fit)
            .overlay {
                if let player {
                    VideoPlayer(player: player)
                } else {
                    // The small copy is already in memory from the library, so there is never an empty card.
                    AssetImage(id: id, side: 300, fill: true)
                    AssetImage(id: id, side: cardSide, fill: true, placeholder: false)
                    if ref?.isVideo == true {
                        Button { play() } label: {
                            Image(systemName: "play.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .frame(width: 76, height: 76)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .buttonStyle(PressStyle())
                        .accessibilityLabel("Play video")
                    }
                }
            }
            .clipped()
            .overlay { (drag.width > 0 ? Theme.keep : Theme.delete).opacity(Double(min(abs(drag.width) / 100, 1)) * 0.22) }
            .overlay(alignment: .topLeading) { stamp(filing.isEmpty ? "Keep" : "Keep \(filing)", "checkmark", Theme.keep, drag.width) }
            .overlay(alignment: .topTrailing) { stamp("Delete", "xmark", Theme.delete, -drag.width) }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.45), radius: 26, y: 16)
            .onDisappear { player?.pause() }
    }

    /// The verdict grows in as the card is pulled to its side.
    private func stamp(_ text: String, _ icon: String, _ color: Color, _ amount: CGFloat) -> some View {
        let strength = Double(min(max(amount / 100, 0), 1))
        return Label(text, systemImage: icon)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Theme.canvas)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(color, in: Capsule())
            .scaleEffect(0.85 + 0.15 * strength)
            .padding(16)
            .opacity(strength)
    }

    private func play() {
        Task {
            guard let item = await model.library.playerItem(for: id) else { return }
            let player = AVPlayer(playerItem: item)
            self.player = player
            player.play()
        }
    }
}
