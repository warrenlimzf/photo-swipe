# Payments: US$1.99 lifetime unlock

Researched 16 Oct 2026. Check Apple's live [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) before submitting; they change a few times a year.

## The short answer to "the backend is hard"

For this app, Apple **is** the backend. Selling a feature unlock inside an iPhone app must go through Apple's In-App Purchase (guideline 3.1.1 names "full versions" and lifetime unlocks). Apple takes the card, charges tax, handles refunds and keeps the receipt. StoreKit 2 hands the app a purchase signed by Apple, and the phone checks that signature itself. So there is no payment server, no database and no card data to protect. Stripe or PayPal inside the app would get it rejected.

What is real work is the **App Store Connect paperwork**, and only the account holder (your brother) can do it.

## How it is built

| Piece | File | What it does |
|---|---|---|
| Rules | `Sources/SwipeCore/Access.swift` (+ `Tests/SwipeCoreTests/AccessTests.swift`) | Intro → paywall → app. A live lifetime purchase unlocks; a refund locks again. |
| StoreKit | `Sources/PhotoSwipeUI/Store.swift` | Loads the product, buys, restores (`AppStore.sync`), listens for Ask to Buy approvals, refunds and purchases from other devices (`Transaction.updates`), only trusts Apple-signed transactions. |
| Screens | `Sources/PhotoSwipeUI/PaywallView.swift` | Three intro pages, then the paywall: live local price, perks, a "once vs yearly" chart, Buy, Restore, Terms, Privacy, confetti on success. |
| Wiring | `Sources/PhotoSwipeUI/RootView.swift` | Shows the gate until unlocked. |
| Local testing | `Configuration/PhotoSwipe.storekit` + shared scheme | Fake App Store inside Xcode. No account needed. |
| Optional server | `server/` | App Store Server Notifications V2 webhook. Not needed; not deployed. |

Debug builds (Xcode Run, `install-local.sh`) show a **Skip (debug)** link, because a free sideloaded build can't buy anything. Release (App Store) builds never contain it.

## Test it now (no Apple account needed)

1. Open `PhotoSwipe.xcodeproj` in Xcode, pick an iPhone simulator, press Run. The shared scheme loads `PhotoSwipe.storekit`.
2. Swipe through the intro, tap **Unlock for $1.99**, confirm the fake sheet. Confetti, then the app opens.
3. Debug → StoreKit → Manage Transactions: delete or refund the purchase. The app locks again on next open.
4. In the `.storekit` file, Editor → "Enable Ask to Buy" to test the pending banner, or tick a StoreKit error to test failures.

## What your brother needs to do (placeholders to fill)

On the shared Apple Developer account (US$99/yr):

1. **Agreements, Tax, and Banking** in App Store Connect: sign the *Paid Apps* agreement, add the bank account and tax forms. Without this, products never load. *(Bank account number goes here, typed by him, never into the code.)*
2. **Small Business Program**: enrol. Apple's cut drops from 30% to 15%, so each $1.99 sale nets about $1.69 before tax.
3. **Create the app record** with bundle id `com.warrenlimzf.photoswipe` (or change it in the project if that id is taken).
4. **Create the in-app purchase**: Features → In-App Purchases → **Non-Consumable**.
   - Product ID: `com.warrenlimzf.photoswipe.lifetime` (must match `Store.lifetimeID` exactly)
   - Price: US$1.99 tier; Apple fills other countries
   - Display name, description, a review screenshot of the paywall
   - Family Sharing: on (recommended; buyers like it)
5. **Privacy policy URL**: required. Placeholder in the app: `https://warrenlimzf.com/photo-swipe/privacy` (page not built yet). Terms link uses Apple's standard EULA.
6. **App Privacy label**: still "Data Not Collected". Apple processes the payment, not us.
7. **Sandbox tester** (Users and Access → Sandbox) to test a real purchase on a phone with a TestFlight build.
8. Submit the IAP **with** the first app version. Apple reviews them together.

Then the only line of code that might change is `Store.lifetimeID`.

## Rules the paywall already follows

- Pay through IAP only; no links or buttons pointing to other payment methods (3.1.1). The US storefront allows external purchase links since 2025, but it's not worth it at $1.99.
- **Restore purchase** button on the paywall (App Review rejects without one).
- Price shown is Apple's localised price (`displayPrice`), never hard-coded.
- Clear what the buyer gets and that it is one payment, no subscription.
- Terms and Privacy links on the paywall.
- No fake urgency, no fake discounts, no competitor names (guidelines 3.1.2 and 2.3).
- The App Store listing must say the app needs a purchase: "Offers In-App Purchases" shows automatically; mention it in the description too.

## Optional: server notifications

Only if you want a live feed of purchases and refunds. Deploy `server/` to Vercel (`npm i`, set `APP_APPLE_ID`, `APP_BUNDLE_ID`, `APP_STORE_ENV`, put Apple's root `.cer` files in `server/certs/`), then paste the URL into App Store Connect → App Information → App Store Server Notifications (Version 2, sandbox and production). App Store Connect's Sales and Trends already shows the same numbers without any of this.
