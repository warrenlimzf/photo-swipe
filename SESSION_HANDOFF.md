# Session handoff — Photo Swipe built, put on Warren's iPhone, and published (14 Oct 2026)

> Persistent resume file. Paste into a fresh session (or auto-load via a SessionStart hook).
> Delta only — project overview, layout, invariants and commands live in CLAUDE.md (auto-loaded).

**Role:** Claude builds, tests in the simulator and installs; Warren reviews on his own iPhone and on the live URL.

## Status — updated 2026-10-14
- App built in one session and running on Warren's iPhone via free signing. He used it and said it works well.
  **It stops opening around 2026-10-21** (7-day limit) and needs a reinstall.
- Look is "Gallery" (see CLAUDE.md invariants). He approved it after rejecting the first redesign as "very AI".
- Public repo `warrenlimzf/photo-swipe` (remote `origin`, branch `main`), MIT, README = install guide + safety notes.
  A fresh clone was built for the simulator and its 11 tests pass.
- Pre-publication history is in the private repo `warrenlimzf/photo-swipe-dev-history` (remote `dev-history`, local
  branch `dev-history-2026-10-14`) because it contains his Team ID and device ID. **Never push that branch to
  `origin`.** A bundle backup sits beside this folder: `../photo-swipe-history-2026-10-14.bundle`.
- Case study live at https://www.warrenlimzf.com/photo-swipe/ and a Photo Swipe card is in the portfolio's Vibecoded
  group (`1.0 - personal website`, commit `79ba9bc`). Outbound links open in a new tab (his standing rule).
- Study note for him: `second-brain/Personal/Dev/Learn - Photo Swipe (building an iPhone app).md`.

## Next actions
1. Weekly reinstall when he asks or by 21 Oct: phone plugged in and unlocked, run `./install-local.sh` (gitignored;
   holds his Team ID and device ID). A Keychain box may ask for his Mac login password; he types it, Always Allow.
2. Apply whatever he reports from real use on the phone.
3. Look at the screens not yet checked in the Gallery look: welcome/permission, Bookmarks, Settings, a video card,
   and a large Dynamic Type size.

## Running state
- Background processes: none
- Dev servers / ports: none
- Worktrees / branches: `main` (public), `dev-history-2026-10-14` (private history, keep local)

## Process cleanup
- Stopped: iPhone 18 Pro simulator (`xcrun simctl shutdown all`); the Claude-in-Chrome Instagram tab was closed.
- Still running on purpose: Xcode (opened for his Apple ID sign-in and team choice; it is his app to close).
- Ownership unverified (left alone): none

## Open items
- His commit email is visible on the public repo. Offered GitHub's no-reply address; no answer yet.
- Two Instagram reels he sent as references (sahni.ai, nateherkai) were read by caption only; the videos need the
  Chrome tab in the foreground.
- Mobbin returns 403 to the built-in browser; needs his logged-in Chrome if he wants it used.
- Undo on a month being re-reviewed clears the decision instead of restoring the old one.
- The simulator still holds test photos copied from his published gallery; harmless, wiped by `simctl erase`.

## Pick up here
If he says the app stopped opening, run `./install-local.sh` with the phone plugged in. Otherwise take his feedback
from using it and change the app, then reinstall the same way.
