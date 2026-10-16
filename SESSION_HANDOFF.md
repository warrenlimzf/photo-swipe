# Session handoff — $1.99 paywall built, then parked: app stays free (16 Oct 2026)

> Persistent resume file. Delta only: project overview, layout, invariants and look rules live in CLAUDE.md.

**Role:** Warren reviews on his iPhone and on the live URL; Claude builds, releases (GitHub Release per version), deploys the landing page and installs with `./install-local.sh`.

## Status — updated 2026-10-16
- **Photo Swipe stays free.** Warren asked for a US$1.99 lifetime unlock, then decided it "doesn't create much economic value" and said to make the app free and forget the payment ideas.
- bd0c806 added the paywall: StoreKit 2 `Sources/PhotoSwipeUI/Store.swift`, three intro pages + `PaywallView.swift`, `SwipeCore/Access.swift` + `AccessTests.swift`, `Configuration/PhotoSwipe.storekit` + shared scheme, optional `server/` App Store Server Notifications V2 webhook, and `docs/payments.md` (Apple IAP rules + App Store Connect checklist for his brother's shared developer account). f598473 reverted all of it. Both commits are pushed to `origin/main`.
- To revive it: `git revert f598473`. Ideas Warren floated if it ever returns: a referral code that unlocks it for free, asked on the same screen as the price (with no hint that codes exist), and US$0.99 if 1.99 feels too dear.
- No release was made and nothing was installed. His phone still runs v1.7.2 (renewal due ~22 Oct).
- Carried from 15 Oct: v1.7.2 album-rail fix is live; the landing page mouse-wheel shake fix (ed9a13c, then 8c9ae27) is still waiting for Warren's check with a real mouse wheel.

## Next actions
1. Warren: scroll warrenlimzf.com/photo-swipe with a real mouse wheel and say if any shake is left. If so, the storm's `left`/`top` animation on 21 photos is the next suspect; move it to `x`/`y` transforms.
2. ~22 Oct: weekly reinstall on his phone with `./install-local.sh`.
3. Queue only (start when he asks): the reorder gesture has no recovery if the system cancels it mid-drag; undo on a re-reviewed month clears instead of restoring; his phone notes on v1.7.x (palette, drift, haptics, landscape swipe, tap-to-pause).

## Running state
- Background processes: none.
- Dev servers / ports: none from this session.
- Simulators: the throwaway "PhotoSwipe Paywall Test" was created and deleted. "iPhone 18 Pro Marketing" and the shared "iPhone 18 Pro" were not touched.
- Branches: `main` (public), `dev-history-2026-10-14` (private, never push).

## Process cleanup
- Stopped: none started this session.
- Still running on purpose: none.
- Ownership unverified (left alone): a `market-dashboard` node process (PID 27197) in `1.0 - personal website/`, started by another chat.

## Open items
- `project.pbxproj` keeps his Team ID locally, uncommitted on purpose.

## Pick up here
Wait for Warren's mouse-wheel verdict on the landing page, or for the 22 Oct reinstall. Don't bring up paid plans unless he does.
