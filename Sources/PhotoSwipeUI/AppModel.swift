import SwiftUI
import SwipeCore

/// A stack of photos to swipe through.
struct Deck: Identifiable {
    let id = UUID()
    /// Also names the card the deck zooms out of.
    let title: String
    let ids: [String]
}

@MainActor @Observable
public final class AppModel {
    let library = PhotoLibrary()
    private(set) var state: ReviewState
    private(set) var months: [MonthGroup] = []
    private(set) var onThisDay: [String] = []
    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "haptics") }
    }

    private let fileURL: URL
    private var saveTask: Task<Void, Never>?
    let calendar = Calendar.current

    public init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("review-state.json")
        state = StateFile.load(from: fileURL)
        hapticsEnabled = UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true
    }

    var today: String { DayStamp.string(Date(), calendar: calendar) }
    var streak: Int { Streak.current(activeDays: state.activeDays, today: Date(), calendar: calendar) }
    var allIDs: [String] { library.assets.map(\.id) }
    var videoIDs: [String] { library.assets.filter(\.isVideo).map(\.id) }
    var bookmarkIDs: [String] { library.assets.map(\.id).filter(state.bookmarks.contains) }
    var reviewedFraction: Double {
        library.assets.isEmpty ? 0 : Double(state.progress(of: allIDs).done) / Double(library.assets.count)
    }
    /// The last seven days, oldest first, with whether each had a swipe.
    var lastWeek: [(label: String, active: Bool)] {
        (0..<7).reversed().compactMap { back in
            guard let day = calendar.date(byAdding: .day, value: -back, to: Date()) else { return nil }
            let symbol = calendar.veryShortWeekdaySymbols[calendar.component(.weekday, from: day) - 1]
            return (symbol, state.activeDays.contains(DayStamp.string(day, calendar: calendar)))
        }
    }

    func reload() async {
        await library.reload()
        let dated = library.assets.map { DatedID(id: $0.id, date: $0.date) }
        months = Grouping.byMonth(dated, calendar: calendar)
        onThisDay = Grouping.onThisDay(dated, today: Date(), calendar: calendar)
        if !library.assets.isEmpty {
            apply { $0.prune(existing: Set(dated.map(\.id))) }
        }
    }

    /// Every change to saved state goes through here so it is written to disk.
    func apply(_ change: (inout ReviewState) -> Void) {
        change(&state)
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    public func saveNow() {
        try? StateFile.save(state, to: fileURL)
    }

    /// Returns false when the user cancels the system prompt or the delete fails.
    func commitDeletes(_ ids: [String]) async -> Bool {
        let bytes = await library.totalSize(of: ids)
        do {
            try await library.delete(ids)
        } catch {
            return false
        }
        apply { $0.commitDeletion(ids: ids, bytes: bytes) }
        saveNow()
        await reload()
        return true
    }

    func resetProgress() {
        apply { $0 = ReviewState() }
        saveNow()
    }
}
