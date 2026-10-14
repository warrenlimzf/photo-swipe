import Foundation

/// One pass through a stack of photos. Swipes write into `ReviewState`; undo takes the last one back.
public struct ReviewSession: Equatable, Sendable {
    public let ids: [String]
    public private(set) var index = 0

    /// Starts on the photos not yet decided. If all are decided, or `onlyUndecided` is false
    /// (an album being cleaned up), the whole stack is offered.
    public init(ids: [String], state: ReviewState, onlyUndecided: Bool = true) {
        let undecided = ids.filter { state.decisions[$0] == nil }
        self.ids = !onlyUndecided || undecided.isEmpty ? ids : undecided
    }

    public var current: String? { index < ids.count ? ids[index] : nil }
    public var next: String? { index + 1 < ids.count ? ids[index + 1] : nil }
    public var isFinished: Bool { index >= ids.count }
    public var canUndo: Bool { index > 0 }
    public var remaining: Int { ids.count - index }

    public mutating func swipe(_ decision: Decision, state: inout ReviewState, day: String) {
        guard let id = current else { return }
        state.decide(id, decision, day: day)
        index += 1
    }

    public mutating func undo(state: inout ReviewState) {
        guard canUndo else { return }
        index -= 1
        state.clearDecision(ids[index])
    }
}
