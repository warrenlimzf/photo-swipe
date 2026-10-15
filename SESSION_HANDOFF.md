# Session handoff — stock-photo marketing rebuild + mouse-wheel scroll fix (in flight, 15 Oct 2026)

> Persistent resume file. Paste into a fresh session (or auto-load via a SessionStart hook).
> Delta only — project overview, layout, invariants, look rules and version lines live in CLAUDE.md (auto-loaded).

**Role:** Warren reviews on his iPhone and on the live URL; Claude builds, releases (GitHub Release per version), deploys the landing page and installs with `./install-local.sh`. Several sibling sessions worked on Photo Swipe today; the coordinating one is "Icon app web-to-app conversion" (local_91157313-51ab-4493-9e78-49083ecc2c21) — report back to it when done.

## Status — updated 2026-10-15 (evening)
- App: v1.7.1 is current (Tangerine default, six user colour themes, whole-card swipe on landscape media). Warren cancelled a black-and-white "Mono" default himself; do not resurrect it.
- Landing page warrenlimzf.com/photo-swipe/ — live state: tangerine look, "Pick your colours" section (efdcdaf), native scroll with no Lenis, real colour photos in the bin pile, black GitHub pill (d87bffd), album renamed Golf → 🌄 Views and "Girlfriend" off the rail in the shared sim (4ccb1af). Old shots showing private album names return 404 via `site/.vercelignore`.
- **New rule (Warren, memory `marketing-no-personal-photos`): no photos of his anywhere in marketing.** The live page, README shots and portfolio card STILL show his library. Rebuild is half done:
  - DONE: 43 Unsplash photos (free Unsplash License, no faces) downloaded, cropped 3:4 1080×1440, EXIF dates spread Jul–Oct 2026. Saved OUTSIDE the repo in `~/Claude-Code/13.0 - photo swipe/stock-photos/` (`proc/` = the photos, `manifest.tsv` = Unsplash photo id + photographer handle + category, `sheet.jpg` = contact sheet, `tools/` = `proc.py`, `pagepics.py`, `sheet.py`).
  - DONE: new simulator **"iPhone 18 Pro Marketing" (D93744A5-F200-4A0A-8B65-A10D7AF30767)** with only the 43 stock photos (Apple's 6 sample photos deleted) and the v1.7.1 build installed (built to `build/`, gitignored). Albums created: ✈️ Trips, 🌄 Views, 🍜 Food. July month half sorted (1 binned city night, beach filed to ✈️ + kept, 2 kept); August untouched. Sim is shut down.
  - DONE + pushed, NOT deployed: `site/img/photos/p01–p21.jpg` now stock (1ffbc57). These feed the photo storm, the drawn-phone swipe deck and the CTA orbit.
  - NOT DONE: all screenshots, README credits, portfolio screens, deploy.
- **Scroll still shakes with a mouse wheel** (Warren, relayed by session local_2b915d2d…). Lenis is gone; suspects in `site/index.html`: hero `heroST` uses `scrub: true` on transforms (~line 532), the storm pin `pin: true, scrub: true, anticipatePin: 1` (~line 568), heavy `will-change: transform` on `.storm .phw`, `.storm .ph`, `.track`, `.btn`.

## Next actions
1. **Finish the album filing on the marketing sim.** `xcrun simctl boot D93744A5-F200-4A0A-8B65-A10D7AF30767`, then `xcrun simctl status_bar D93744A5-F200-4A0A-8B65-A10D7AF30767 override --time "9:41" --batteryState charged --batteryLevel 100 --cellularMode active --cellularBars 4 --wifiBars 3 --dataNetwork wifi`, attach the panel, launch `com.warrenlimzf.photoswipe`. Swipe screen coordinates (points): bin (105,790), keep (295,790), rail ✈️ (114,653) 🌄 (171,653) 🍜 (229,653); tapping a rail emoji only marks it, then press keep. Rest of July in order: views→🌄 keep, city bin, views→✈️ keep, views→🌄 keep, pets keep, views→🌄 keep, food→🍜 keep. August in order: pets keep, trips→✈️, food→🍜, views→🌄, pets bin, food→🍜, pets keep, views→🌄, pets bin, pets keep, city bin, city bin, views→🌄, food→🍜. Leave September and October unsorted so Months shows "left" counts. Take screenshots with `xcrun simctl io <udid> screenshot` (the tool's own screenshots lag), and screenshot before every tap: Library scroll position shifts.
2. **Take every shot from that sim** (1206×2622): Library top, Months (scroll so the header isn't clipped), Swipe mid-drag with the Keep stamp (background `sleep 2.2; simctl io screenshot` while a `touch_path` holds a ~85 pt drag right, then drag back), Review grid (the ~6 binned), an album (🌄 Views), and the palettes strip (`docs/screenshots/palettes.jpg`: look at the current one first and rebuild the same layout, six Library tops, one per palette via ⋯ → Colours; set back to Tangerine after).
3. **Swap them in.**
   - Landing page: new `site/img/v18-*.jpg` at 804×1748, referenced in the four `.shot` slots; add the superseded `v16-*`/`v17-*` to `site/.vercelignore`.
   - README: `docs/screenshots/{library,months,swipe,review,palettes}.jpg` at 603×1311 (palettes same size as now).
   - Portfolio: `~/Claude-Code/1.0 - personal website/public/works/apps/photoswipe-{swipe,library}.jpg` at 640×1391 (pull first; icon, stage and glow are already done).
   - Credits: add `NOTICE.md` (or a README "Photo credits" line) saying the demo photos are from Unsplash under the Unsplash License, and listing the photographer handles from `manifest.tsv` with links `https://unsplash.com/@handle`.
4. **Fix the mouse-wheel shake** in `site/index.html`. Try in this order and test with REAL wheel steps in Chrome, not `scrollTo` or a trackpad:
   - (a) hero `scrub: true` → `scrub: 0.4`;
   - (b) storm: drop `anticipatePin`, try `pinType: "transform"` or a shorter pin `end: "+=160%"`, and `scrub: 0.4`;
   - (c) remove `will-change` from `.storm .ph`, `.btn` and `.track` (keep it only while animating);
   - (d) check that the live swipe deck in the drawn phone doesn't wobble during page scroll (the `.stage` parallax rotates it).

   A small scrub value smooths the animation only; it never hijacks the scroll itself, so it doesn't break his "native scroll" rule. Record the root cause and the fix in `DEBUG_LOG.md`.
5. **Verify** at the 10 sizes (memory `marketing-pages-few-words`): no sideways scroll, no text over the phone, icons and palette name inside their panel. Check every new image by eye for faces or any of his own content. Run `grep -rn "Girlfriend\|Golf" site README.md docs`.
6. **Ship.** `cd site && vercel deploy --prod --yes --scope warrenlimzf-projects`. Commit only the files you touched (never `git add -A`; `project.pbxproj` stays out) and push both repos. Confirm with `curl` / md5 that the live files are the new ones. Report back to local_91157313… with the commits and the list of images replaced, and confirm that no image of Warren's remains in any deployed marketing file (photos p01–p21, v18 shots, README, portfolio).
7. Afterwards: shut down the marketing sim (keep it for future shots). The shared "iPhone 18 Pro" (8480D10E…) still holds his real library plus a 4 s wallpaper test video. Leave it alone unless Warren asks.

## Running state
- Background processes: none
- Dev servers / ports: none (temporary `python3 -m http.server 8765` shells were stopped)
- Worktrees / branches: `main` (public), `dev-history-2026-10-14` (private, never push to origin)
- Simulators: "iPhone 18 Pro Marketing" D93744A5-F200-4A0A-8B65-A10D7AF30767, stock-only, shut down, keep. Shared "iPhone 18 Pro" 8480D10E-708E-4750-8ED8-53CF3E55D567 left booted by another session.

## Process cleanup
- Stopped: background shells be045wq97, bg4d823p1 and bcogiae8h (`python3 -m http.server 8765`, local preview), verified; marketing simulator shut down.
- Still running on purpose: none
- Ownership unverified (left alone): CLI-owned MCP servers (drawio, playwright, react-bits), which exit with the CLI; the shared "iPhone 18 Pro" simulator, booted by another session.

## Open items
- `project.pbxproj` keeps his Team ID locally, uncommitted on purpose (stage via `git hash-object` of a copy with `DEVELOPMENT_TEAM` lines stripped).
- The live page shows his photos until step 6 ships; the repo already has the stock p01–p21.
- Older: reorder gesture has no recovery if the system cancels it mid-drag (unseen); undo on a re-reviewed month clears instead of restoring; Warren's phone notes on v1.7.x (palette he keeps, drift, haptics, landscape swipe, tap-to-pause) still pending.

## Pick up here
Boot the "iPhone 18 Pro Marketing" simulator, finish filing July and August into ✈️/🌄/🍜 (step 1), then take the five shots plus the palettes strip and run steps 3–6 in one pass, mouse-wheel fix included.
