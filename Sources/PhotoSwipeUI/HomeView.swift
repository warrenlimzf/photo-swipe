import SwiftUI
import SwipeCore

private enum Route: Hashable {
    case bookmarks, stats, settings
    case album(String)
}

/// The library: every month as a mosaic of its own photos.
struct HomeView: View {
    let ready: Bool
    @Environment(AppModel.self) private var model
    @State private var deck: Deck?
    @State private var route: Route?
    @State private var showTrash = false
    @State private var editor: EditorTarget?
    @Namespace private var zoom

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    summary
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .rise(ready, order: 0)
                    if !model.state.pendingDeletes.isEmpty {
                        trashRow
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                            .transition(.opacity)
                    }
                    AlbumsSection(onOpen: { route = .album($0.id) }, onNew: { editor = .new })
                        .padding(.top, 28)
                        .rise(ready, order: 1)
                    if !model.onThisDay.isEmpty {
                        onThisDay
                            .padding(.top, 36)
                            .rise(ready, order: 1)
                    }
                    ForEach(model.months, id: \.key) { month in
                        MonthSection(group: month, title: monthName(month.key)) {
                            Haptics.tick(model.hapticsEnabled)
                            deck = Deck(title: monthName(month.key), ids: month.ids, month: month.key)
                        }
                        .zoomSource(monthName(month.key), in: zoom)
                        .rise(ready, order: 2)
                    }
                    if model.library.isLoading && model.library.assets.isEmpty {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
                    } else if model.library.assets.isEmpty {
                        ContentUnavailableView("No photos", systemImage: "photo.on.rectangle",
                                               description: Text("Take a few and they'll show up here."))
                            .padding(.top, 60)
                    }
                }
                .padding(.bottom, 48)
                .animation(.spring(duration: 0.4), value: model.state.pendingDeletes.isEmpty)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Section("Swipe through") {
                            Button("Recents", systemImage: "clock") { open("Recents", Array(model.allIDs.prefix(100))) }
                            Button("Random", systemImage: "shuffle") { open("Random", Array(model.allIDs.shuffled().prefix(50))) }
                            Button("Videos", systemImage: "video") { open("Videos", model.videoIDs) }
                        }
                        Section {
                            Button("Bookmarks", systemImage: "bookmark") { route = .bookmarks }
                            Button("Stats", systemImage: "chart.bar") { route = .stats }
                            Button("Settings", systemImage: "gearshape") { route = .settings }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel("More")
                }
            }
            .navigationDestination(item: $route) { route in
                switch route {
                case .bookmarks: BookmarksView()
                case .stats: StatsView()
                case .settings: SettingsView()
                case .album(let id): AlbumView(shelfID: id)
                }
            }
            .refreshable { await model.reload() }
        }
        .cover(item: $deck) { deck in
            SwipeDeckView(deck: deck, state: model.state)
                .zoomTransition(deck.title, in: zoom)
        }
        .sheet(isPresented: $showTrash) { ReviewDeleteView() }
        .sheet(item: $editor) { target in AlbumEditor(editing: target.album) }
    }

    private func open(_ title: String, _ ids: [String]) {
        guard !ids.isEmpty else { return }
        Haptics.tick(model.hapticsEnabled)
        deck = Deck(title: title, ids: ids)
    }

    private func monthName(_ key: MonthKey) -> String { model.monthName(key) }

    /// Three figures on one line, divided by hairlines, over a thin line of progress.
    private var summary: some View {
        let progress = model.state.progress(of: model.allIDs)
        return VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 0) {
                Figure(value: formatBytes(model.state.bytesFreed), label: "Freed")
                Rectangle().fill(Theme.hairline).frame(width: 1, height: 34).padding(.horizontal, 18)
                Figure(value: "\(progress.done)/\(progress.total)", label: "Reviewed")
                Rectangle().fill(Theme.hairline).frame(width: 1, height: 34).padding(.horizontal, 18)
                Figure(value: "\(model.streak)", label: "Day streak")
                Spacer(minLength: 0)
            }
            ProgressLine(value: model.reviewedFraction, height: 2)
        }
    }

    private var trashRow: some View {
        Button { showTrash = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                    .symbolEffect(.bounce, value: model.state.pendingDeletes.count)
                Text(model.state.pendingDeletes.count == 1 ? "1 photo to delete" : "\(model.state.pendingDeletes.count) photos to delete")
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Spacer()
                Text("Review")
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            }
            .font(.body.weight(.medium))
            .foregroundStyle(Theme.delete)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(Theme.delete.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressStyle())
    }

    private var onThisDay: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("On this day").eyebrow()
                Spacer()
                Text(Date().formatted(.dateTime.day().month(.wide))).eyebrow()
            }
            .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(model.onThisDay.prefix(12), id: \.self) { id in
                        Tile(id: id, side: 600)
                            .frame(width: 210, height: 270)
                            .overlay(alignment: .bottomLeading) {
                                if let ref = model.library.ref(id) {
                                    Text(ref.date.formatted(.dateTime.year()))
                                        .font(.headline)
                                        .monospacedDigit()
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.6), radius: 4)
                                        .padding(14)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .onTapGesture { open("On this day", model.onThisDay) }
        }
        .zoomSource("On this day", in: zoom)
    }
}

private struct Figure: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
            Text(label).eyebrow()
        }
    }
}

/// One month: the year in small capitals, the month's name, a mosaic of its newest photos, a line of progress.
private struct MonthSection: View {
    let group: MonthGroup
    let title: String
    let action: () -> Void
    @Environment(AppModel.self) private var model

    var body: some View {
        let progress = model.state.progress(of: group.ids)
        let done = progress.done == progress.total
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(group.key.year)).eyebrow().monospacedDigit()
                        HStack(spacing: 10) {
                            Text(model.calendar.monthSymbols[max(0, min(11, group.key.month - 1))])
                                .font(.title.bold())
                                .foregroundStyle(done ? Theme.muted : Theme.ink)
                            if done {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Theme.keep)
                                    .symbolEffect(.bounce, value: done)
                                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                            }
                        }
                    }
                    Spacer()
                    Text(done ? "Done" : "\(progress.done) / \(progress.total)")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(Theme.muted)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 20)
                .padding(.top, 44)
                .padding(.bottom, 16)
                Mosaic(ids: group.ids)
                    .saturation(done ? 0 : 1)
                    .opacity(done ? 0.4 : 1)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 16)
                ProgressLine(value: Double(progress.done) / Double(max(progress.total, 1)), height: 2,
                             tint: done ? Theme.keep : Theme.ink)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
            }
            .animation(.spring(duration: 0.4), value: done)
            .contentShape(Rectangle())
        }
        .buttonStyle(DimStyle())
        .accessibilityLabel("\(title), \(progress.done) of \(progress.total) reviewed")
    }
}

/// Up to six photos: one large, two stacked beside it, three in a row beneath.
private struct Mosaic: View {
    let ids: [String]
    private let gap: CGFloat = 3

    var body: some View {
        switch ids.count {
        case 0:
            EmptyView()
        case 1:
            Tile(id: ids[0], side: 900).aspectRatio(1.5, contentMode: .fit)
        case 2:
            HStack(spacing: gap) {
                Tile(id: ids[0], side: 600)
                Tile(id: ids[1], side: 600)
            }
            .aspectRatio(2, contentMode: .fit)
        default:
            VStack(spacing: gap) {
                // Three columns wide, two rows tall: the lead photo takes two columns.
                Color.clear
                    .aspectRatio(1.5, contentMode: .fit)
                    .overlay {
                        GeometryReader { geo in
                            let unit = (geo.size.width - 2 * gap) / 3
                            HStack(spacing: gap) {
                                Tile(id: ids[0], side: 900).frame(width: unit * 2 + gap)
                                VStack(spacing: gap) {
                                    Tile(id: ids[1])
                                    Tile(id: ids[2])
                                }
                            }
                        }
                    }
                if ids.count >= 6 {
                    HStack(spacing: gap) {
                        Tile(id: ids[3])
                        Tile(id: ids[4])
                        Tile(id: ids[5])
                            .overlay {
                                if ids.count > 6 {
                                    ZStack {
                                        Color.black.opacity(0.55)
                                        Text("+\(ids.count - 6)")
                                            .font(.title3.weight(.semibold))
                                            .monospacedDigit()
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                    }
                    .aspectRatio(3, contentMode: .fit)
                }
            }
        }
    }
}
