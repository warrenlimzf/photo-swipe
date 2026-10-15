import SwiftUI
import SwipeCore

/// The switch at the bottom of the library: months still to sort, or months already finished.
private enum MonthFilter: String, CaseIterable, Identifiable {
    case toDo = "To do", done = "Done"
    var id: Self { self }
}

private enum Route: Hashable {
    case bookmarks, stats, settings, colours
    case album(String)
}

/// The library: a brand hero with what is left to sort, quick decks, albums, then every month
/// as a card holding a mosaic of its own photos.
struct HomeView: View {
    let ready: Bool
    @Environment(AppModel.self) private var model
    @State private var deck: Deck?
    @State private var route: Route?
    @State private var showTrash = false
    @State private var editor: EditorTarget?
    @State private var filter: MonthFilter = .toDo
    @State private var scrolledPastHero = false
    @Namespace private var zoom
    @Namespace private var segment

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
              ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        LibraryHero(topInset: geo.safeAreaInsets.top, menu: { menu })
                            .rise(ready, order: 0)
                        quickRow
                            .padding(.horizontal, 16)
                            .padding(.top, -34)
                            .rise(ready, order: 1)
                        // Albums lead, then anything waiting to be deleted. Freed / reviewed / streak
                        // live in Stats (⋯ menu), not here.
                        AlbumsSection(onOpen: { route = .album($0.id) }, onNew: { editor = .new })
                            .padding(.top, 30)
                            .rise(ready, order: 2)
                        if !model.state.pendingDeletes.isEmpty {
                            trashRow
                                .padding(.horizontal, 16)
                                .padding(.top, 26)
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                                .rise(ready, order: 3)
                        }
                        if !model.onThisDay.isEmpty {
                            onThisDay
                                .padding(.top, 30)
                                .rise(ready, order: 3)
                        }
                        HStack(alignment: .firstTextBaseline) {
                            Text("Months").sectionTitle()
                            Spacer()
                            Text(filter == .toDo ? "To do" : "Done").eyebrow()
                                .contentTransition(.opacity)
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 32)
                        .padding(.bottom, 14)
                        .rise(ready, order: 4)
                        ForEach(shownMonths, id: \.key) { month in
                            MonthSection(group: month, title: monthName(month.key)) {
                                deck = Deck(title: monthName(month.key), ids: month.ids, month: month.key)
                            }
                            .zoomSource(monthName(month.key), in: zoom)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                            .rise(ready, order: 4)
                        }
                        if shownMonths.isEmpty && !model.library.assets.isEmpty {
                            emptyFilter.padding(.top, 30)
                        }
                        if model.library.isLoading && model.library.assets.isEmpty {
                            ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
                        } else if model.library.assets.isEmpty {
                            ContentUnavailableView("No photos", systemImage: "photo.on.rectangle")
                                .padding(.top, 60)
                        }
                    }
                    .padding(.bottom, 90)
                    .animation(.spring(duration: 0.4), value: model.state.pendingDeletes.isEmpty)
                    .animation(.spring(duration: 0.4), value: filter)
                }
                .noTopEdgeEffect()
                .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 300 } action: { _, now in
                    scrolledPastHero = now
                }
                StatusScrim(height: geo.safeAreaInsets.top, shown: scrolledPastHero)
              }
              .ignoresSafeArea(edges: .top)
            }
            .background(Theme.page.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                if !model.library.assets.isEmpty { filterBar }
            }
            .hideNavBar()
            .navigationTitle("Library")
            .navigationDestination(item: $route) { route in
                switch route {
                case .bookmarks: BookmarksView()
                case .stats: StatsView()
                case .settings: SettingsView()
                case .colours: ColoursView()
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

    @ViewBuilder private var menu: some View {
        Section {
            Button("Bookmarks", systemImage: "bookmark") { route = .bookmarks }
            Button("Stats", systemImage: "chart.bar") { route = .stats }
            Button("Colours", systemImage: "paintpalette") { route = .colours }
            Button("Settings", systemImage: "gearshape") { route = .settings }
        }
    }

    /// Three quick decks as white cards that overlap the hero's bottom edge.
    private var quickRow: some View {
        HStack(spacing: 10) {
            QuickButton(icon: "clock.fill", label: "Recents") { open("Recents", Array(model.allIDs.prefix(100))) }
            QuickButton(icon: "shuffle", label: "Random") { open("Random", Array(model.allIDs.shuffled().prefix(50))) }
            QuickButton(icon: "video.fill", label: "Videos") { open("Videos", model.videoIDs) }
                .disabled(model.videoIDs.isEmpty)
        }
    }

    private func open(_ title: String, _ ids: [String]) {
        guard !ids.isEmpty else { return }
        deck = Deck(title: title, ids: ids)
    }

    private func monthName(_ key: MonthKey) -> String { model.monthName(key) }

    private func isDone(_ month: MonthGroup) -> Bool {
        let p = model.state.progress(of: month.ids)
        return p.done == p.total
    }

    /// Finished months move out of To do and into Done, so the list in front of you is only work left.
    private var shownMonths: [MonthGroup] {
        model.months.filter { isDone($0) == (filter == .done) }
    }

    /// To do / Done: a white capsule floating over the list; the brand pill slides between the two.
    private var filterBar: some View {
        let finished = model.months.filter(isDone).count
        let counts: [MonthFilter: Int] = [.toDo: model.months.count - finished, .done: finished]
        return HStack(spacing: 4) {
            ForEach(MonthFilter.allCases) { option in
                let on = filter == option
                Button {
                    withAnimation(.spring(duration: 0.4, bounce: 0.25)) { filter = option }
                } label: {
                    HStack(spacing: 6) {
                        Text(option.rawValue).font(.system(.subheadline, design: .rounded, weight: .semibold))
                        Text("\(counts[option] ?? 0)").font(.numeral(15))
                            .foregroundStyle(on ? .white.opacity(0.75) : Theme.dim)
                    }
                    .foregroundStyle(on ? .white : Theme.muted)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background {
                        if on {
                            Capsule().fill(Theme.cta)
                                .shadow(color: Theme.b500.opacity(0.35), radius: 8, y: 4)
                                .matchedGeometryEffect(id: "pill", in: segment)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(PressStyle())
            }
        }
        .padding(5)
        .background(.white, in: Capsule())
        .shadow(color: Theme.ink.opacity(0.12), radius: 18, y: 8)
        .padding(.horizontal, 64)
        .padding(.bottom, 6)
        .sensoryFeedback(.selection, trigger: filter)
    }

    @ViewBuilder private var emptyFilter: some View {
        if filter == .toDo {
            ContentUnavailableView("All caught up", systemImage: "checkmark.circle.fill")
                .foregroundStyle(Theme.keep, Theme.ink)
        } else {
            ContentUnavailableView("Nothing done yet", systemImage: "tray")
                .foregroundStyle(Theme.dim, Theme.ink)
        }
    }

    private var trashRow: some View {
        let count = model.state.pendingDeletes.count
        return Button { showTrash = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Theme.deleteFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .symbolEffect(.bounce, value: count)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(count)")
                        .font(.numeral(24))
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())
                    Text("to delete").font(.subheadline).foregroundStyle(Theme.muted)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("Review")
                    Image(systemName: "chevron.right").font(.caption.weight(.bold))
                }
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(Theme.delete)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(Theme.delete.opacity(0.1), in: Capsule())
            }
            .padding(14)
            .card(26)
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(count == 1 ? "1 photo to delete, review" : "\(count) photos to delete, review")
    }

    private var onThisDay: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("On this day").sectionTitle()
                Spacer()
                Text(Date().formatted(.dateTime.day().month(.wide))).eyebrow()
            }
            .padding(.horizontal, 22)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.onThisDay.prefix(12), id: \.self) { id in
                        Tile(id: id, side: 600)
                            .frame(width: 190, height: 250)
                            .overlay(alignment: .bottomLeading) {
                                if let ref = model.library.ref(id) {
                                    Text(ref.date.formatted(.dateTime.year()))
                                        .font(.numeral(15))
                                        .foregroundStyle(Theme.ink)
                                        .padding(.horizontal, 12)
                                        .frame(height: 30)
                                        .background(.white, in: Capsule())
                                        .padding(12)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .shadow(color: Theme.ink.opacity(0.12), radius: 12, y: 6)
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 10)
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .onTapGesture {
                Haptics.press()
                open("On this day", model.onThisDay)
            }
        }
        .zoomSource("On this day", in: zoom)
    }
}

/// The big colour block on Library: wordmark and menu on top, how many photos are left to sort,
/// and the print stack swiping by itself.
private struct LibraryHero<MenuItems: View>: View {
    let topInset: CGFloat
    @ViewBuilder var menu: MenuItems
    @Environment(AppModel.self) private var model

    var body: some View {
        let p = model.state.progress(of: model.allIDs)
        let left = p.total - p.done
        let percent = p.total == 0 ? 0 : Int((Double(p.done) / Double(p.total) * 100).rounded(.down))
        ZStack(alignment: .bottomLeading) {
            HeroShape(radius: 40)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Wordmark(size: 22)
                    Spacer()
                    Menu { menu } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.18), in: Circle())
                    }
                    .accessibilityLabel("More")
                    .simultaneousGesture(TapGesture().onEnded { Haptics.press() })
                }
                Spacer(minLength: 0)
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        if p.total > 0 && left == 0 {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 64, weight: .bold))
                            Text("All sorted").font(.system(.title3, design: .rounded, weight: .semibold))
                        } else {
                            Text("\(left)")
                                .font(.numeral(left > 9999 ? 56 : 72))
                                .contentTransition(.numericText())
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text("to sort")
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Text("\(percent)% done")
                            .font(.numeral(14, weight: .semibold))
                            .padding(.horizontal, 11)
                            .frame(height: 28)
                            .background(.white.opacity(0.18), in: Capsule())
                            .padding(.top, 6)
                    }
                    .foregroundStyle(.white)
                    Spacer(minLength: 8)
                    PrintStack(size: 172)
                        .offset(x: 6, y: -4)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, topInset + 6)
            .padding(.bottom, 58)
        }
        .frame(height: topInset + 330)
        .animation(.snappy, value: left)
    }
}

/// A white card with an icon in a brand-tinted square and one word.
private struct QuickButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.b500)
                    .frame(width: 40, height: 40)
                    .background(Theme.b100, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .card(24)
        }
        .buttonStyle(PressStyle())
        .opacity(isEnabled ? 1 : 0.45)
    }
}

/// One month as a white card: its name and year, how many are left, a mosaic of its newest
/// photos, a progress bar.
private struct MonthSection: View {
    let group: MonthGroup
    let title: String
    let action: () -> Void
    @Environment(AppModel.self) private var model

    var body: some View {
        let progress = model.state.progress(of: group.ids)
        let done = progress.done == progress.total
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(model.calendar.monthSymbols[max(0, min(11, group.key.month - 1))])
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text(String(group.key.year))
                        .font(.numeral(17, weight: .semibold))
                        .foregroundStyle(Theme.dim)
                    Spacer()
                    if done {
                        Label("Done", systemImage: "checkmark")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(Theme.keep)
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(Theme.keep.opacity(0.12), in: Capsule())
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(progress.total - progress.done)")
                                .font(.numeral(20))
                                .foregroundStyle(Theme.ink)
                                .contentTransition(.numericText())
                            Text("left").font(.subheadline).foregroundStyle(Theme.dim)
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top, 4)
                Mosaic(ids: group.ids)
                    .overlay { if done { DoneStamp().transition(.opacity) } }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                ProgressLine(value: Double(progress.done) / Double(max(progress.total, 1)), height: 8, done: done)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
            }
            .padding(12)
            .card(30)
            .animation(.spring(duration: 0.4), value: done)
            .contentShape(Rectangle())
        }
        .buttonStyle(DimStyle())
        .accessibilityLabel("\(title), \(progress.done) of \(progress.total) reviewed")
    }
}

/// A big green tick over a finished month's photos, so Done reads at a glance.
/// The photos stay in full colour under a light veil; nothing is greyed out.
private struct DoneStamp: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
            Image(systemName: "checkmark")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(Theme.keepFill, in: Circle())
                .overlay { Circle().strokeBorder(.white.opacity(0.9), lineWidth: 3) }
                .shadow(color: .black.opacity(0.45), radius: 14, y: 6)
                .scaleEffect(shown || reduceMotion ? 1 : 0.6)
                .opacity(shown ? 1 : 0)
        }
        .allowsHitTesting(false)
        .onAppear { withAnimation(.spring(duration: 0.45, bounce: 0.4)) { shown = true } }
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
