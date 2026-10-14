import Foundation

public struct DatedID: Equatable, Sendable {
    public let id: String
    public let date: Date
    public init(id: String, date: Date) {
        self.id = id
        self.date = date
    }
}

public struct MonthKey: Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int
    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }
    public static func < (a: MonthKey, b: MonthKey) -> Bool {
        (a.year, a.month) < (b.year, b.month)
    }
}

public struct MonthGroup: Equatable, Sendable {
    public let key: MonthKey
    public let ids: [String]
}

public enum Grouping {
    /// Newest month first; inside a month, newest photo first.
    public static func byMonth(_ items: [DatedID], calendar: Calendar) -> [MonthGroup] {
        var buckets: [MonthKey: [DatedID]] = [:]
        for item in items {
            let c = calendar.dateComponents([.year, .month], from: item.date)
            buckets[MonthKey(year: c.year ?? 0, month: c.month ?? 0), default: []].append(item)
        }
        return buckets.keys.sorted(by: >).map { key in
            MonthGroup(key: key, ids: buckets[key]!.sorted { $0.date > $1.date }.map(\.id))
        }
    }

    /// The next older month that still has undecided photos, for "Next month" on the finish screen.
    public static func nextMonth(after key: MonthKey, in months: [MonthGroup], state: ReviewState) -> MonthGroup? {
        guard let i = months.firstIndex(where: { $0.key == key }) else { return nil }
        return months[(i + 1)...].first { group in group.ids.contains { state.decisions[$0] == nil } }
    }

    /// Photos taken on today's month and day in an earlier year, newest first.
    public static func onThisDay(_ items: [DatedID], today: Date, calendar: Calendar) -> [String] {
        let now = calendar.dateComponents([.year, .month, .day], from: today)
        return items.filter {
            let c = calendar.dateComponents([.year, .month, .day], from: $0.date)
            return c.month == now.month && c.day == now.day && (c.year ?? 0) < (now.year ?? 0)
        }
        .sorted { $0.date > $1.date }
        .map(\.id)
    }
}

public enum DayStamp {
    public static func string(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

public enum Streak {
    /// Consecutive active days ending today. A streak that reached yesterday still counts until today ends.
    public static func current(activeDays: Set<String>, today: Date, calendar: Calendar) -> Int {
        var day = today
        if !activeDays.contains(DayStamp.string(day, calendar: calendar)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while activeDays.contains(DayStamp.string(day, calendar: calendar)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}
