import SwiftUI
import SwipeCore

/// The last stop before anything is deleted. Tap a photo to rescue it.
struct ReviewDeleteView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var size: Int64?
    @State private var isDeleting = false

    var body: some View {
        let ids = model.state.pendingDeletes
        NavigationStack {
            HeroScreen(title: "To delete", subtitle: size.map { $0 > 0 ? byteFormatter.string(fromByteCount: $0) : " " } ?? " ") {
                if ids.isEmpty {
                    ContentUnavailableView("Nothing to delete", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Theme.keep, Theme.ink)
                        .padding(.top, 40)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Tap to keep", systemImage: "hand.tap.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(Theme.b700)
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(Theme.b100, in: Capsule())
                        LazyVGrid(columns: thumbColumns, spacing: 4) {
                            ForEach(ids, id: \.self) { id in
                                Button {
                                    Haptics.tick(model.hapticsEnabled)
                                    withAnimation(.spring(duration: 0.35)) {
                                        model.apply { $0.decide(id, .keep, day: model.today) }
                                    }
                                } label: {
                                    Thumb(id: id)
                                }
                                .buttonStyle(PressStyle(haptic: false))
                                .transition(.scale(scale: 0.8).combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Pill(title: deleteTitle(ids.count), icon: "trash.fill", kind: .delete, busy: isDeleting) {
                        Task {
                            isDeleting = true
                            let deleted = await model.commitDeletes(ids)
                            isDeleting = false
                            if deleted {
                                Haptics.success(model.hapticsEnabled)
                                dismiss()
                            }
                        }
                    }
                    .disabled(ids.isEmpty)
                    .opacity(ids.isEmpty ? 0.4 : 1)
                    .animation(.snappy, value: ids.count)
                    Text("Recently Deleted keeps them 30 days")
                        .font(.caption)
                        .foregroundStyle(Theme.dim)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 8)
                .background {
                    LinearGradient(colors: [Theme.page.opacity(0), Theme.page], startPoint: .top, endPoint: .init(x: 0.5, y: 0.35))
                        .ignoresSafeArea()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .task(id: ids.count) { size = await model.library.totalSize(of: ids) }
        }
    }

    private func deleteTitle(_ count: Int) -> String {
        "Delete \(count) \(count == 1 ? "photo" : "photos")"
    }
}

struct BookmarksView: View {
    @Environment(AppModel.self) private var model
    @State private var deck: Deck?

    var body: some View {
        let ids = model.bookmarkIDs
        HeroScreen(title: "Bookmarks", subtitle: ids.isEmpty ? nil : "\(ids.count)") {
            if !ids.isEmpty {
                Button { deck = Deck(title: "Bookmarks", ids: ids) } label: {
                    Label("Swipe", systemImage: "hand.draw.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.b700)
                        .padding(.horizontal, 16)
                        .frame(height: 40)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(PressStyle())
            }
        } content: {
            if ids.isEmpty {
                ContentUnavailableView("Nothing bookmarked", systemImage: "bookmark")
                    .foregroundStyle(Theme.dim, Theme.ink)
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: thumbColumns, spacing: 4) {
                    ForEach(ids, id: \.self) { id in
                        Thumb(id: id)
                            .contextMenu {
                                Button("Remove bookmark", systemImage: "bookmark.slash") {
                                    withAnimation(.spring(duration: 0.35)) {
                                        model.apply { $0.toggleBookmark(id) }
                                    }
                                }
                            }
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .cover(item: $deck) { deck in
            SwipeDeckView(deck: deck, state: model.state)
        }
    }
}

/// The big percentage lives in the hero; figures sit in white cards below.
struct StatsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let total = model.library.assets.count
        let fraction = model.reviewedFraction
        HeroScreen(title: "Stats") {
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.numeral(40))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("reviewed")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        } content: {
            VStack(spacing: 16) {
                ProgressLine(value: fraction, height: 10, track: Theme.b100)
                    .padding(.horizontal, 8)
                HStack(spacing: 12) {
                    figure(formatBytes(model.state.bytesFreed), "freed", "sparkles", tint: Theme.b500)
                    figure("\(model.streak)", "day streak", "flame.fill", tint: Theme.b700)
                }
                week
                VStack(spacing: 0) {
                    row("Deleted", "\(model.state.deletedCount)", "trash.fill", Theme.delete)
                    divider
                    row("Kept", "\(model.state.keptCount)", "checkmark", Theme.keep)
                    divider
                    row("To delete", "\(model.state.pendingDeletes.count)", "clock.fill", Theme.b500)
                    divider
                    row("Bookmarked", "\(model.state.bookmarks.count)", "bookmark.fill", Theme.b500)
                    divider
                    row("In library", "\(total)", "photo.on.rectangle", Theme.muted)
                    divider
                    row("Days swiped", "\(model.state.activeDays.count)", "calendar", Theme.muted)
                }
                .padding(.vertical, 6)
                .card(26)
            }
            .padding(.horizontal, 16)
        }
    }

    private var divider: some View {
        Rectangle().fill(Theme.hairline).frame(height: 1).padding(.leading, 66)
    }

    private func figure(_ value: String, _ label: String, _ icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(Theme.b100, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.numeral(24)).foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.6)
                Text(label).font(.subheadline).foregroundStyle(Theme.dim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .card(26)
    }

    /// Seven dots, filled orange on the days with a swipe.
    private var week: some View {
        HStack {
            ForEach(Array(model.lastWeek.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(day.active ? AnyShapeStyle(Theme.cta) : AnyShapeStyle(Theme.fill))
                        if day.active {
                            Image(systemName: "checkmark").font(.caption.weight(.heavy)).foregroundStyle(.white)
                        }
                    }
                    .frame(width: 32, height: 32)
                    Text(day.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.dim)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .card(26)
    }

    private func row(_ label: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            Text(label).font(.body).foregroundStyle(Theme.ink)
            Spacer()
            Text(value).font(.numeral(17, weight: .semibold)).foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmReset = false

    var body: some View {
        @Bindable var model = model
        HeroScreen(title: "Settings") {
            VStack(spacing: 16) {
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        icon("iphone.radiowaves.left.and.right", Theme.b500)
                        Toggle("Haptics", isOn: $model.hapticsEnabled)
                            .tint(Theme.b500)
                            .sensoryFeedback(.selection, trigger: model.hapticsEnabled)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    Rectangle().fill(Theme.hairline).frame(height: 1).padding(.leading, 66)
                    NavigationLink { ColoursView() } label: {
                        HStack(spacing: 14) {
                            HeroFill(animated: false)
                                .frame(width: 36, height: 36)
                                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            Text("Colours").foregroundStyle(Theme.ink)
                            Spacer()
                            Text(Theme.palette.name).foregroundStyle(Theme.dim)
                            Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.dim)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressStyle())
                    Rectangle().fill(Theme.hairline).frame(height: 1).padding(.leading, 66)
                    Button { openSystemSettings() } label: {
                        HStack(spacing: 14) {
                            icon("photo.on.rectangle", Theme.b500)
                            Text("Photo access").foregroundStyle(Theme.ink)
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.dim)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressStyle())
                }
                .padding(.vertical, 6)
                .card(26)

                Button { confirmReset = true } label: {
                    HStack(spacing: 14) {
                        icon("arrow.counterclockwise", Theme.delete)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset progress").foregroundStyle(Theme.delete)
                            Text("Photos and albums stay").font(.footnote).foregroundStyle(Theme.dim)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .card(26)
                }
                .buttonStyle(PressStyle())

                Label("Photos never leave this phone", systemImage: "lock.fill")
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.dim)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 16)
        }
        .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                Haptics.warning(model.hapticsEnabled)
                model.resetProgress()
            }
        } message: {
            Text("Clears decisions, bookmarks and stats. Your photos are not touched.")
        }
    }

    private func icon(_ name: String, _ tint: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 36, height: 36)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}
