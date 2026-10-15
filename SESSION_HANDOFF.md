# Session handoff — v1.6.0 Foodie restyle, v1.7.0 colour themes, v1.7.1 landscape swipe fix (15 Oct 2026)

> Persistent resume file. Paste into a fresh session (or auto-load via a SessionStart hook).
> Delta only — project overview, layout, invariants and commands live in CLAUDE.md (auto-loaded).

**Role:** Warren reviews on his iPhone; Claude builds, releases (GitHub Release per version) and installs with `./install-local.sh`.

## Status — updated 2026-10-15
- v1.6.0: whole app restyled from the black Gallery look to the Foodie standard. Warren picked **Tangerine** from three simulator directions (Grape / Tangerine / Berry). New icon (`tools/make_icon.py`), README screenshots refreshed. Logic untouched; 24 tests pass.
- New shared pieces in `Brand.swift`: `PrintStack` (self-swiping drawing), `HeroShape`, `CompactHero`, `HeroScreen` (pushed screens keep the system back button and edge swipe), `StatusScrim`, `Pill`, `Wordmark`. `PressStyle` buzzes on every press.
- Status bar fix and what not to retry: `DEBUG_LOG.md`.
- Verified in the simulator (iPhone 18 Pro, iOS 27, real photo set): Library, swipe + drag stamp, finish screen, review grid + Apple's delete prompt (answered Don't Allow), album + select mode, Bookmarks, Stats, Settings, edge-swipe back. Not seen in the simulator: the permission screen (access already granted), the album editor sheet.

- v1.7.0: Warren said colour should not be one fixed pick ("the user can change their colors", gradients, ideas from React Bits). Added ⋯ → Colours (`Palette.swift`): six gradient palettes, a drifting 3×3 MeshGradient hero modelled on React Bits' Aurora, a Moving colours switch, and a matching alternate app icon per palette (verified the iOS icon-change notice in the simulator). Comparison image: docs/screenshots/palettes.jpg.

- v1.7.1 (commit 00cae58, Release published, installed on his iPhone over Wi-Fi): landscape photos/videos only swiped on the picture itself. Every card is now a 3:4 portrait rectangle with `contentShape`; wider media is fitted over a blurred copy; video plays in a bare `AVPlayerLayer` (`PlayerLayer`, hit testing off), tap the card to pause/resume. Verified in a throwaway simulator: left swipe from the top band on a playing landscape video, right swipe from the bottom band on a landscape photo, portrait photo still fills. Cause and don't-retry: `DEBUG_LOG.md`.
- Shared "iPhone 18 Pro" simulator: this session left a 4 s test video (from the "iMac Blue" wallpaper) in its library; the landing-page session was told to drop it during its stock-photo rebuild (message queued, not confirmed read).
- Uncommitted `site/img/photos/*.jpg` changes in the working tree belong to the landing-page session (stock-photo swap); not touched here.

## Next actions
1. Wait for Warren's notes on v1.6.0 from his phone.
2. Landing page warrenlimzf.com/photo-swipe still shows the old black screens; it needs new shots and probably the tangerine colour (ask first).

## Running state
- Background processes: none
- Dev servers / ports: none
- Worktrees / branches: `main` (public), `dev-history-2026-10-14` (private, never push to origin)

## Process cleanup
- Stopped: no background processes started (helper listing showed only CLI-owned MCP servers). Throwaway simulator "PS swipe test" (9B58C8BB) shut down and deleted.
- Still running on purpose: none
- Ownership unverified (left alone): none

## Open items
- `project.pbxproj` keeps his Team ID locally, uncommitted on purpose (stage via `git hash-object` of a copy with `DEVELOPMENT_TEAM` lines stripped, as done this session).
- Reorder gesture has no recovery if the system cancels it mid-drag (emoji could stay lifted until next touch); not seen, unverified.
- Older items still open: Albums screenshot on the landing page shows his "Girlfriend" album (swap offered); landing page screenshots now predate v1.5.0 Library layout; deferred album review minors (see git history of this file, 14 Oct); undo on a re-reviewed month clears instead of restoring.

## Pick up here
Ask Warren how v1.7.1 feels on his phone, especially swiping landscape shots and tap-to-pause on videos; v1.7.0 palette feedback is also still open.
