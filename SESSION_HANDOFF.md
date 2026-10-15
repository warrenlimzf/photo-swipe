# Session handoff — v1.6.0 Foodie restyle, v1.7.0 colour themes, v1.7.1 swipe fix (15 Oct 2026)

> Persistent resume file. Paste into a fresh session (or auto-load via a SessionStart hook).
> Delta only — project overview, layout, invariants, look rules and version lines live in CLAUDE.md (auto-loaded).

**Role:** Warren reviews on his iPhone; Claude builds, releases (GitHub Release per version) and installs with `./install-local.sh`.

## Status — updated 2026-10-15
- Shipped today, all released and installed on his iPhone: v1.6.0 (Foodie restyle; he picked Tangerine from Grape / Tangerine / Berry mock-ups), v1.7.0 (⋯ → Colours: six gradient palettes, drifting mesh hero after React Bits' Aurora, matching alternate icons), v1.7.1 (another session: every swipe card is a 3:4 rectangle so drags anywhere swipe; landscape media sits over a blurred copy; video plays in a bare player layer, tap the card to pause; cause in `DEBUG_LOG.md`).
- **Decision:** a black-and-white "Mono" default was requested via the parent session, then Warren cancelled it himself ("since you've updated the logo, then that's fine. just keep it and we're good"). Tangerine stays the default look and icon. Nothing of Mono was committed; do not resurrect it.
- Landing page warrenlimzf.com/photo-swipe: rebuilt in tangerine with fresh screens (eba3591), then a "pick your colours" section (efdcdaf) and polish (d87bffd) by sibling sessions. README screenshots re-taken with renamed albums (4ccb1af).
- Status bar gotchas (iOS 27 ignores the Info.plist key for covers; see-through bar greys the hero) are in `DEBUG_LOG.md`.
- Not seen in the simulator: the permission screen, the album editor sheet. Not felt on a phone yet: the moving gradient, the haptics.

## Next actions
1. Wait for Warren's notes from his phone on v1.7.x (palette he keeps, whether the drift is too much, haptics, swiping landscape shots, tap-to-pause on videos).

## Running state
- Background processes: none
- Dev servers / ports: none
- Worktrees / branches: `main` (public), `dev-history-2026-10-14` (private, never push to origin)
- Simulator iPhone 18 Pro (8480D10E-708E-4750-8ED8-53CF3E55D567) holds the real photo set; its home-screen icon was left on an alternate from icon tests. It also holds a 4 s test video (from the "iMac Blue" wallpaper) left by the v1.7.1 session; drop it in the stock-photo rebuild.

## Process cleanup
- Stopped: none (the only background shell this session started, a timed screenshot, exited on its own)
- Still running on purpose: none
- Ownership unverified (left alone): CLI-owned MCP servers (drawio, playwright, react-bits); they exit with the CLI

## Open items
- `project.pbxproj` keeps his Team ID locally, uncommitted on purpose (stage via `git hash-object` of a copy with `DEVELOPMENT_TEAM` lines stripped).
- Uncommitted `site/img/photos/p01–p09.jpg` changes in the working tree belong to a landing-page session, not this one; leave them to it.
- Older: reorder gesture has no recovery if the system cancels it mid-drag (unseen); undo on a re-reviewed month clears instead of restoring; deferred album review minors (git history of this file, 14 Oct).

## Pick up here
Ask Warren how v1.7.x feels on his phone and which colour theme he settled on.
