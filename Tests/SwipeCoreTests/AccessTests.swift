import Testing
@testable import SwipeCore

private let lifetime = "com.warrenlimzf.photoswipe.lifetime"

@Test func newUserSeesIntroThenPaywall() {
    #expect(AccessGate.screen(seenIntro: false, unlocked: false) == .intro)
    #expect(AccessGate.screen(seenIntro: true, unlocked: false) == .paywall)
}

@Test func buyerGoesStraightToTheApp() {
    // A reinstall on a new phone: the purchase comes back before the intro is ever seen.
    #expect(AccessGate.screen(seenIntro: false, unlocked: true) == .app)
    #expect(AccessGate.screen(seenIntro: true, unlocked: true) == .app)
}

@Test func lifetimePurchaseUnlocks() {
    let owned = [Ownership(productID: lifetime, revoked: false)]
    #expect(AccessGate.unlocked(by: owned, product: lifetime))
}

@Test func refundedPurchaseLocksAgain() {
    let refunded = [Ownership(productID: lifetime, revoked: true)]
    #expect(!AccessGate.unlocked(by: refunded, product: lifetime))
}

@Test func otherProductsDoNotUnlock() {
    let other = [Ownership(productID: "com.someone.else", revoked: false)]
    #expect(!AccessGate.unlocked(by: other, product: lifetime))
    #expect(!AccessGate.unlocked(by: [], product: lifetime))
}

@Test func onePurchaseAmongManyIsEnough() {
    let mixed = [
        Ownership(productID: lifetime, revoked: true),
        Ownership(productID: lifetime, revoked: false),
    ]
    #expect(AccessGate.unlocked(by: mixed, product: lifetime))
}
