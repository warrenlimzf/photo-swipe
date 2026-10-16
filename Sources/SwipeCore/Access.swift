/// Who gets in. The app is a one-off lifetime unlock bought through Apple's In-App Purchase;
/// StoreKit says what the person owns, this decides what that means. No StoreKit types here, so
/// the rules are tested on the Mac.

/// One verified transaction, boiled down to the two facts that matter.
public struct Ownership: Equatable, Sendable {
    public let productID: String
    /// True once Apple refunds it or pulls it from a Family Sharing group.
    public let revoked: Bool

    public init(productID: String, revoked: Bool) {
        self.productID = productID
        self.revoked = revoked
    }
}

public enum AccessGate {
    public enum Screen: Equatable, Sendable { case intro, paywall, app }

    /// The intro pages first, then the paywall, and the app once paid. A buyer reinstalling
    /// never sees either.
    public static func screen(seenIntro: Bool, unlocked: Bool) -> Screen {
        if unlocked { return .app }
        return seenIntro ? .paywall : .intro
    }

    /// Any live (not refunded) transaction for the lifetime product unlocks the app.
    public static func unlocked(by owned: [Ownership], product: String) -> Bool {
        owned.contains { $0.productID == product && !$0.revoked }
    }
}
