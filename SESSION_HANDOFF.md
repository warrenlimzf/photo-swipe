# Session handoff — stock-photo marketing shipped + mouse-wheel shake fixed (15 Oct 2026, late)


> **16 Oct 2026, paywall built then parked: the app stays FREE (Warren's call: "doesn't create much economic value").**
> bd0c806 added a US$1.99 lifetime unlock (StoreKit 2 `Store.swift`, intro + `PaywallView.swift`, `SwipeCore/Access.swift`
> + tests, Xcode `.storekit` test file, optional `server/` webhook, `docs/payments.md` with the App Store Connect checklist for
> his brother's shared account). Reverted in the next commit. To bring it back: `git revert <that revert commit>`.
> Ideas he floated if it ever returns: a referral code that unlocks free, asked on the same screen as the price (no hint that
> codes exist), and US$0.99 if 1.99 feels too dear. Nothing was released or installed; his phone still runs v1.7.2.


> **15 Oct 2026 (~23:00), v1.7.2 album-rail fix (separate agent, a02faf7, release v1.7.2, installed on his iPhone):** the
> rail's hold-to-reorder gesture swallowed every drag, so with 7+ albums the + was unreachable. Now a UIKit long-press that
> gives up when the finger moves, so the rail scrolls; interrupted holds drop the emoji back; adding an album scrolls to the
> end. Test simulator "PhotoSwipe RailFix Test" (49EC49C3-2A21-431A-B74F-8DB50E9CD7F5) kept, shut down. Warren to check the
> live landing page with a real mouse wheel (scroll-shake fix ed9a13c).
> Persistent resume file. Delta only: project overview, layout, invariants and look rules live in CLAUDE.md.

**Role:** Warren reviews on his iPhone and on the live URL; Claude builds, releases (GitHub Release per version), deploys the landing page and installs with `./install-local.sh`. The coordinating session for today's Photo Swipe work is "Icon app web-to-app conversion" (local_91157313-51ab-4493-9e78-49083ecc2c21).

## Status — 2026-10-15 (late)
- App: v1.7.1 still current. No app code changed this session.
- **No photo of Warren's is left in any deployed marketing file.** Live and checked by md5 against the repo:
  - Landing page warrenlimzf.com/photo-swipe/: `img/photos/p01–p21` (Unsplash) and the four shots `img/v18-{months,swipe,review,album}.jpg`. Old `v13`–`v17` shots return 404 (`site/.vercelignore`). Footer links the photo credits.
  - README: `docs/screenshots/{library,months,swipe,review,palettes}.jpg` retaken. The old palettes strip also showed the "Girlfriend" album; gone now.
  - Portfolio card: `1.0 - personal website/public/works/apps/photoswipe-{swipe,library}.jpg` (commit 24cee1f there, auto-deployed).
  - Credits: `NOTICE.md` lists the 39 Unsplash photographers (Unsplash License); README "Credit and licence" links it.
- Marketing sim "iPhone 18 Pro Marketing" (D93744A5-…): July and August fully sorted (albums ✈️ Trips 4, 🌄 Views 6, 🍜 Food 4; 6 in the bin, not deleted), September 13 and October 6 left unsorted. Palette set back to Tangerine. Shut down, keep it.
- Mouse-wheel shake fixed (ed9a13c): `scrub: true` → 0.4/0.5, no `anticipatePin`, fewer `will-change`, tilt ignores post-scroll pointermove. Root cause and numbers in `DEBUG_LOG.md`.
- New `tools/sim-driver/`: an XCUITest runner that taps and drags the installed app on a simulator. Xcode 27 has no Simulator.app window, so this is how marketing shots get taken now (instructions at the top of `c.sh`).
- Commits: 52309c5 (shots + credits), ed9a13c (scroll fix), plus this handoff commit; portfolio 24cee1f.

## Next actions
1. Warren: scroll the live page with a real mouse wheel and say if any shake is left. If so, the next suspect is the storm animating `left`/`top` on 21 photos (layout every frame); move it to `x`/`y` transforms.
2. Report back to local_91157313… with the commits above (the coordinating session asked for it).
3. Older open items, queue only: reorder gesture has no recovery if the system cancels it mid-drag; undo on a re-reviewed month clears instead of restoring; Warren's phone notes on v1.7.x (palette he keeps, drift, haptics, landscape swipe, tap-to-pause) still pending.

## Running state
- Background processes: none (driver test run ended with `quit`; local `http.server 8766` stopped).
- Simulators: marketing sim shut down. Shared "iPhone 18 Pro" (8480D10E…) untouched; it still holds his real library.
- Branches: `main` (public), `dev-history-2026-10-14` (private, never push).

## Open items
- `project.pbxproj` keeps his Team ID locally, uncommitted on purpose.
- `Sources/PhotoSwipeUI/AlbumRail.swift` has uncommitted edits from another session; left alone.
