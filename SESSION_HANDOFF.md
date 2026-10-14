# Session handoff — photo-swipe

Last updated: 2026-10-14 (session opened from `second-brain/`).

## Where it stands
- Builds and runs on the iPhone 18 Pro simulator (Xcode 27, iOS 27). Minimum iOS is 18 (zoom transition).
- 11 logic tests pass (`./test.sh`).
- Walked in the simulator: splash, library, month mosaic, zoom into the swipe deck, swipe keep/delete, undo,
  info, bookmark, finish screen, review grid, rescue, the real iOS delete prompt, stats.
- **Look: "Gallery"**, chosen by Warren after he rejected the first redesign (navy hero card, stat tiles, cover cards)
  as "very AI". Black, photo-first, system type. Awaiting his verdict on this version.
- Not yet looked at after the Gallery rewrite: the welcome/permission screen, Bookmarks, Settings, a video card.
- **Installed on Warren's iPhone on 2026-10-14** (free Personal Team, expires after 7 days, so due again by 2026-10-21). Awaiting his first impressions from the real phone.

## Published (2026-10-14)
- Repo is **public**: github.com/warrenlimzf/photo-swipe, one clean commit, MIT. README = install guide + safety notes.
- The eight earlier commits live in the private repo `warrenlimzf/photo-swipe-dev-history` (local branch
  `dev-history-2026-10-14`, remote `dev-history`) because they contain his Team ID and device ID. Never push that
  branch to `origin`. A bundle backup sits beside this folder.
- Case study live at warrenlimzf.com/photo-swipe; card added under Vibecoded on the portfolio.
- A fresh clone of the public repo was built for the simulator and its tests pass.

## Warren's decisions
- Free route: his own phone via a free Apple ID (app expires every 7 days). No App Store, no US$99, for now.
- No paywall, ads or tracking.

## Next
1. His feedback from using it on the phone.
2. Weekly reinstall (phone plugged in and unlocked): run `./install-local.sh`. That file is gitignored because it
   holds his Apple team ID and the phone's device ID; the project file itself carries no team. The first signed build
   pops a Keychain box: he types his Mac login password and clicks Always Allow.
3. Still unchecked in the Gallery look: welcome screen, Bookmarks, Settings, a video card, large Dynamic Type.

## Open
- Undo on a month being re-reviewed clears the decision instead of restoring the old one.

## Running state / process cleanup
- Simulator shut down at the end of the session.
- No dev servers or watchers.
