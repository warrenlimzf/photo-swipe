import Foundation
import Testing
@testable import SwipeCore

private var utc: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}

private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
    utc.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
}

@Test func swipeRecordsDecisionAndAdvances() {
    var state = ReviewState()
    var session = ReviewSession(ids: ["a", "b", "c"], state: state)
    session.swipe(.delete, state: &state, day: "2026-10-14")
    session.swipe(.keep, state: &state, day: "2026-10-14")
    #expect(state.decisions == ["a": .delete, "b": .keep])
    #expect(session.current == "c")
    #expect(state.pendingDeletes == ["a"])
    #expect(state.activeDays == ["2026-10-14"])
}

@Test func undoRestoresPreviousPhoto() {
    var state = ReviewState()
    var session = ReviewSession(ids: ["a", "b"], state: state)
    #expect(!session.canUndo)
    session.swipe(.delete, state: &state, day: "d")
    session.undo(state: &state)
    #expect(session.current == "a")
    #expect(state.decisions.isEmpty)
    session.undo(state: &state)
    #expect(session.current == "a")
}

@Test func undoWorksAfterTheLastCard() {
    var state = ReviewState()
    var session = ReviewSession(ids: ["a"], state: state)
    session.swipe(.keep, state: &state, day: "d")
    #expect(session.isFinished)
    session.swipe(.keep, state: &state, day: "d")
    session.undo(state: &state)
    #expect(session.current == "a")
    #expect(state.decisions.isEmpty)
}

@Test func sessionResumesOnUndecidedPhotos() {
    var state = ReviewState()
    state.decide("a", .keep, day: "d")
    #expect(ReviewSession(ids: ["a", "b", "c"], state: state).ids == ["b", "c"])
    state.decide("b", .keep, day: "d")
    state.decide("c", .keep, day: "d")
    #expect(ReviewSession(ids: ["a", "b", "c"], state: state).ids == ["a", "b", "c"])
}

@Test func commitDeletionUpdatesTotals() {
    var state = ReviewState()
    state.decide("a", .delete, day: "d")
    state.decide("b", .keep, day: "d")
    state.toggleBookmark("a")
    state.commitDeletion(ids: ["a"], bytes: 2_000)
    #expect(state.decisions == ["b": .keep])
    #expect(state.bookmarks.isEmpty)
    #expect(state.deletedCount == 1)
    #expect(state.bytesFreed == 2_000)
    #expect(state.reviewedCount == 2)
}

@Test func pruneDropsMissingPhotos() {
    var state = ReviewState()
    state.decide("a", .keep, day: "d")
    state.decide("gone", .delete, day: "d")
    state.toggleBookmark("gone")
    state.prune(existing: ["a"])
    #expect(state.decisions == ["a": .keep])
    #expect(state.bookmarks.isEmpty)
}

@Test func progressCountsDecidedOnly() {
    var state = ReviewState()
    state.decide("a", .keep, day: "d")
    #expect(state.progress(of: ["a", "b", "c"]) == (1, 3))
}

@Test func groupsByMonthNewestFirst() {
    let items = [
        DatedID(id: "jan1", date: date(2025, 1, 3)),
        DatedID(id: "mar", date: date(2025, 3, 9)),
        DatedID(id: "jan2", date: date(2025, 1, 20)),
        DatedID(id: "old", date: date(2023, 12, 31)),
    ]
    let groups = Grouping.byMonth(items, calendar: utc)
    #expect(groups.map(\.key) == [MonthKey(year: 2025, month: 3), MonthKey(year: 2025, month: 1), MonthKey(year: 2023, month: 12)])
    #expect(groups[1].ids == ["jan2", "jan1"])
}

@Test func onThisDayMatchesEarlierYearsOnly() {
    let items = [
        DatedID(id: "today", date: date(2026, 10, 14)),
        DatedID(id: "y2024", date: date(2024, 10, 14)),
        DatedID(id: "y2021", date: date(2021, 10, 14)),
        DatedID(id: "other", date: date(2024, 10, 15)),
    ]
    #expect(Grouping.onThisDay(items, today: date(2026, 10, 14), calendar: utc) == ["y2024", "y2021"])
}

@Test func streakCountsConsecutiveDays() {
    let today = date(2026, 10, 14)
    #expect(Streak.current(activeDays: [], today: today, calendar: utc) == 0)
    #expect(Streak.current(activeDays: ["2026-10-14", "2026-10-13", "2026-10-11"], today: today, calendar: utc) == 2)
    #expect(Streak.current(activeDays: ["2026-10-13", "2026-10-12"], today: today, calendar: utc) == 2)
    #expect(Streak.current(activeDays: ["2026-10-12"], today: today, calendar: utc) == 0)
}

@Test func stateSurvivesSaveAndLoad() throws {
    var state = ReviewState()
    state.decide("a", .delete, day: "2026-10-14")
    state.toggleBookmark("b")
    state.bytesFreed = 42
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    try StateFile.save(state, to: url)
    #expect(StateFile.load(from: url) == state)
    #expect(StateFile.load(from: url.appendingPathExtension("missing")) == ReviewState())
}
