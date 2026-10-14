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
            ScrollView {
                if ids.isEmpty {
                    ContentUnavailableView("Nothing to delete", systemImage: "checkmark.circle",
                                           description: Text("Photos you swipe left will wait here."))
                        .padding(.top, 60)
                } else {
                    Text("Tap any photo to keep it.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    LazyVGrid(columns: thumbColumns, spacing: 2) {
                        ForEach(ids, id: \.self) { id in
                            Button {
                                Haptics.tick(model.hapticsEnabled)
                                withAnimation(.spring(duration: 0.35)) {
                                    model.apply { $0.decide(id, .keep, day: model.today) }
                                }
                            } label: {
                                Thumb(id: id)
                            }
                            .buttonStyle(PressStyle())
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                        }
                    }
                }
            }
            .background(Theme.canvas.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Button {
                        Task {
                            isDeleting = true
                            let deleted = await model.commitDeletes(ids)
                            isDeleting = false
                            if deleted {
                                Haptics.success(model.hapticsEnabled)
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isDeleting { ProgressView().tint(Theme.canvas) }
                            Text(deleteTitle(ids.count))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                        }
                        .font(.headline)
                        .foregroundStyle(Theme.canvas)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Theme.delete, in: Capsule())
                    }
                    .buttonStyle(PressStyle())
                    .disabled(ids.isEmpty || isDeleting)
                    .opacity(ids.isEmpty ? 0.4 : 1)
                    .animation(.snappy, value: ids.count)
                    Text("They'll sit in Recently Deleted for 30 days.")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(.bar)
            }
            .navigationTitle("To delete")
            .inlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .task(id: ids.count) { size = await model.library.totalSize(of: ids) }
        }
    }

    private func deleteTitle(_ count: Int) -> String {
        let noun = count == 1 ? "photo" : "photos"
        guard let size, size > 0 else { return "Delete \(count) \(noun)" }
        return "Delete \(count) \(noun) · \(byteFormatter.string(fromByteCount: size))"
    }
}

struct BookmarksView: View {
    @Environment(AppModel.self) private var model
    @State private var deck: Deck?

    var body: some View {
        let ids = model.bookmarkIDs
        ScrollView {
            if ids.isEmpty {
                ContentUnavailableView("Nothing bookmarked", systemImage: "bookmark",
                                       description: Text("Bookmark a photo while swiping if you can't decide yet."))
                    .padding(.top, 60)
            } else {
                LazyVGrid(columns: thumbColumns, spacing: 2) {
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
            }
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Bookmarks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Swipe") { deck = Deck(title: "Bookmarks", ids: ids) }
                    .disabled(ids.isEmpty)
            }
        }
        .cover(item: $deck) { deck in
            SwipeDeckView(deck: deck, state: model.state)
        }
    }
}

/// Plain figures in a native list. One big number, then rows.
struct StatsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let total = model.library.assets.count
        let fraction = model.reviewedFraction
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(Int((fraction * 100).rounded()))%")
                        .font(.numeral(72))
                        .foregroundStyle(Theme.ink)
                    Text("of your library reviewed")
                        .font(.body)
                        .foregroundStyle(Theme.muted)
                    ProgressLine(value: fraction).padding(.top, 6)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 8, trailing: 4))
            }
            Section {
                row("Space freed", formatBytes(model.state.bytesFreed))
                row("Deleted", "\(model.state.deletedCount)")
                row("Kept", "\(model.state.keptCount)")
                row("Waiting to be deleted", "\(model.state.pendingDeletes.count)")
                row("Bookmarked", "\(model.state.bookmarks.count)")
                row("Photos in library", "\(total)")
            }
            Section("This week") {
                HStack {
                    ForEach(Array(model.lastWeek.enumerated()), id: \.offset) { _, day in
                        VStack(spacing: 8) {
                            Circle()
                                .fill(day.active ? Theme.accent : Theme.hairline)
                                .frame(width: 28, height: 28)
                            Text(day.label)
                                .font(.caption2)
                                .foregroundStyle(Theme.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 6)
                row("Current streak", model.streak == 1 ? "1 day" : "\(model.streak) days")
                row("Days swiped", "\(model.state.activeDays.count)")
            }
        }
        .navigationTitle("Stats")
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .monospacedDigit()
                .foregroundStyle(Theme.muted)
        }
    }
}

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var confirmReset = false

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                Toggle("Haptics", isOn: $model.hapticsEnabled)
                Button("Photo access") { openSystemSettings() }
            }
            Section {
                Button("Reset all progress", role: .destructive) { confirmReset = true }
            } footer: {
                Text("Clears your decisions, bookmarks and stats. Your photos are not touched.")
            }
            Section {
                Label("Your photos stay on this phone. No account, no ads, no tracking.", systemImage: "lock")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { model.resetProgress() }
        }
    }
}
