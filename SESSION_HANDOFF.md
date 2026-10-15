# Session handoff — v1.4.0 to v1.5.0: one-album filing, smooth rail reorder, Library reshuffle (15 Oct 2026)

> Persistent resume file. Paste into a fresh session (or auto-load via a SessionStart hook).
> Delta only — project overview, layout, invariants and commands live in CLAUDE.md (auto-loaded).

**Role:** Warren reviews on his iPhone; Claude builds, releases (GitHub Release per version) and installs with `./install-local.sh`.

## Status — updated 2026-10-15
- Shipped and installed on his iPhone (Wi-Fi): v1.4.0, v1.4.1, v1.5.0. Version lines are in CLAUDE.md; bug notes in `DEBUG_LOG.md` (new file).
- v1.4.0: rail single-select; filing into one album unfiles it from other rail albums (`FilingLedger.otherAlbums`, `takeBackMoves` for undo); `ReviewState.moveShelf`; `.interactiveDismissDisabled()` on `SwipeDeckView`.
- v1.4.1: rail reorder rebuilt as a custom long-press (0.22s) + drag gesture in `AlbumRail.swift` (system onDrag felt laggy, left a ghost). Edit / Remove moved to "hold without moving" → confirmationDialog.
- v1.5.0: Library order is Albums → to-delete row → months; Freed/Reviewed/Streak summary removed from Library (still in Stats); `DoneStamp` big green tick over finished months' mosaic; progress bars 6pt (months) / 5pt (deck).
- Warren: "you did exactly what I've said". Not yet confirmed: how the v1.4.1 drag feels on his phone.
- Install restarted the 7-day signing clock: next renewal ~22 Oct.

## Next actions
1. Wait for Warren's notes. Likely tuning: drag lift timing / bounce, DoneStamp size or veil opacity (0.28).

## Running state
- Background processes: none
- Dev servers / ports: none
- Worktrees / branches: `main` (public), `dev-history-2026-10-14` (private, never push to origin)

## Process cleanup
- Stopped: none started this session (helper script listing showed only CLI-owned MCP servers)
- Still running on purpose: none
- Ownership unverified (left alone): none

## Open items
- `project.pbxproj` keeps his Team ID locally, uncommitted on purpose (stage via `git hash-object` of a copy with `DEVELOPMENT_TEAM` lines stripped, as done this session).
- Reorder gesture has no recovery if the system cancels it mid-drag (emoji could stay lifted until next touch); not seen, unverified.
- Older items still open: Albums screenshot on the landing page shows his "Girlfriend" album (swap offered); landing page screenshots now predate v1.5.0 Library layout; deferred album review minors (see git history of this file, 14 Oct); undo on a re-reviewed month clears instead of restoring.

## Pick up here
Ask Warren how v1.5.0 feels on his phone, especially the hold-and-drag on the emoji rail.
