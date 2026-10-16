import Foundation
import Observation
import StoreKit
import SwipeCore

/// The one file that talks to StoreKit. Photo Swipe sells a single non-consumable, "Lifetime",
/// through Apple's In-App Purchase (App Store guideline 3.1.1: unlocking an app's features must
/// go through IAP). Apple runs the payment, the receipt and the refunds; StoreKit 2 hands back
/// transactions signed by Apple (JWS) and checks the signature on the phone, so the app needs
/// no server of its own. `server/` holds an optional webhook for refund alerts; see
/// docs/payments.md.
@MainActor @Observable
final class Store {
    /// PLACEHOLDER until the product exists in App Store Connect: the Product ID must match
    /// this string exactly (Features → In-App Purchases → Non-Consumable). The same id is in
    /// `Configuration/PhotoSwipe.storekit` for local testing.
    static let lifetimeID = "com.warrenlimzf.photoswipe.lifetime"

    enum Phase: Equatable {
        case idle
        case buying
        /// Ask to Buy: a parent has to approve. The app unlocks by itself when they do.
        case pending
        case failed(String)
    }

    private(set) var product: Product?
    private(set) var unlocked: Bool
    private(set) var phase: Phase = .idle
    private(set) var restoring = false
    /// Set once the product list call has come back, found or not.
    private(set) var loaded = false

    private var updates: Task<Void, Never>?
    /// Last known answer, so a buyer opening the app offline is never shown the paywall while
    /// StoreKit catches up. StoreKit stays the source of truth: `refresh()` overwrites it.
    private let cacheKey = "store.unlocked"

    init() {
        unlocked = UserDefaults.standard.bool(forKey: cacheKey)
        updates = listen()
        Task {
            await loadProduct()
            await refresh()
        }
    }

    /// Price as Apple formats it for the person's storefront ("US$1.99", "S$2.98"…). Never
    /// hard-code the price: it differs by country and Apple's tax tables.
    var price: String { product?.displayPrice ?? "US$1.99" }

    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.lifetimeID]).first
        } catch {
            product = nil
        }
        loaded = true
    }

    func buy() async {
        if product == nil { await loadProduct() }
        guard let product else {
            phase = .failed("The App Store isn't reachable. Check your connection and try again.")
            return
        }
        phase = .buying
        do {
            switch try await product.purchase() {
            case .success(let result):
                let transaction = try checked(result)
                await transaction.finish()
                await refresh()
                phase = .idle
            case .pending:
                phase = .pending
            case .userCancelled:
                phase = .idle
            @unknown default:
                phase = .idle
            }
        } catch {
            phase = .failed("The purchase didn't go through. You haven't been charged.")
        }
    }

    /// The Restore button (App Review checks for it). `AppStore.sync()` asks the person to sign
    /// in if needed and pulls every purchase on their Apple Account onto this phone.
    func restore() async {
        restoring = true
        defer { restoring = false }
        try? await AppStore.sync()
        await refresh()
        if !unlocked {
            phase = .failed("No purchase found on this Apple Account.")
        }
    }

    /// Re-reads what the Apple Account owns. Refunds and revoked Family Sharing drop out of
    /// `currentEntitlements`, so this also locks the app again after a refund.
    func refresh() async {
        var owned: [Ownership] = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checked(result) else { continue }
            owned.append(Ownership(productID: transaction.productID, revoked: transaction.revocationDate != nil))
        }
        set(AccessGate.unlocked(by: owned, product: Self.lifetimeID))
    }

    func clearError() { if case .failed = phase { phase = .idle } }

    #if DEBUG
    /// Debug builds only (Xcode Run and `install-local.sh`): a free sideloaded build can't buy
    /// anything, so this lets the developer past the paywall. Never compiled into App Store builds.
    func developerUnlock() { set(true) }
    #endif

    private func set(_ value: Bool) {
        unlocked = value
        UserDefaults.standard.set(value, forKey: cacheKey)
    }

    /// Purchases that finish outside `buy()`: Ask to Buy approvals, a purchase made on another
    /// device, promoted purchases from the App Store page, refunds.
    private func listen() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.checked(result) {
                    await transaction.finish()
                }
                await self.refresh()
                if self.unlocked, self.phase == .pending { self.phase = .idle }
            }
        }
    }

    /// Only trust what Apple signed. A jailbroken phone or a tampered receipt fails here.
    private nonisolated func checked<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified(_, let error): throw error
        }
    }
}
