# Session handoff — v1.3.0, README rebuilt, landing page rebuilt as marketing (14 Oct 2026)

> Persistent resume file. Paste into a fresh session (or auto-load via a SessionStart hook).
> Delta only — project overview, layout, invariants and commands live in CLAUDE.md (auto-loaded).

**Role:** Warren reviews on his iPhone and on the live URL; Claude builds, releases and deploys.

## Status — updated 2026-10-14
- v1.3.0 released and installed on Warren's iPhone OVER WI-FI (devicectl transport `localNetwork`). Next renewal ~21 Oct, cable not needed if phone is on the Mac's Wi-Fi.
- README rebuilt around three paths (first install / update / 7-day renewal) with a shared "Your two Xcode settings" section (Team + Bundle ID reset on every download). No personal names in it. All in-page anchors verified on GitHub's rendered page.
- Landing page warrenlimzf.com/photo-swipe rebuilt as a marketing page: live auto-swiping deck inside a drawn iPhone (drag, keys, undo work), upright keep/bin word beside it, pinned "Thousands of photos." storm on a shuffled jittered grid ending "Keep the keepers. Bin the blurry bits.", four screens with one word each, marquee, "Get it." CTA. Measured clean at 10 screen sizes. Warren: "very good".
- Hall Aircon demo page also changed this session (see 7.0 hall-aircond); Warren then said to leave it until its features change.

## Next actions
1. Wait for Warren's next review notes on the landing page; he asked earlier for the hero to keep visibly moving on scroll (now stronger) and may want a specific older motion back.
2. Icon and marketing design tweaks are "later" per Warren; do not start.

## Running state
- Background processes: none
- Dev servers / ports: none
- Worktrees / branches: `main` (public), `dev-history-2026-10-14` (private, never push to origin)

## Process cleanup
- Stopped: next dev on :3077 (shells ba0skgrh8, brvse8pz2), python http.server on :4173 (several, by PID). Verified no listeners on either port.
- Still running on purpose: none
- Ownership unverified (left alone): none (Playwright MCP Chrome is CLI-owned and exits with the CLI)

## Open items
- The Albums screenshot on the landing page shows his real album "Girlfriend"; offered to swap, no answer.
- Unused old images `site/img/library.jpg`, `months.jpg` still in the repo (kept, §1).
- `project.pbxproj` keeps his Team ID locally, uncommitted on purpose.
- Older items still open from before: commit email visible on the public repo; undo on a re-reviewed month clears instead of restoring.

## Pick up here
Ask Warren for his next round of notes on warrenlimzf.com/photo-swipe; everything is shipped and live.
