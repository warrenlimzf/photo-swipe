# photo-swipe — router

iPhone app: clear the camera roll by swiping. Right keeps, left deletes, undo takes the last swipe
back, and nothing is deleted until the user confirms a review grid. Same job as Swipewipe
(App Store id1583884012), built from scratch with its own name, look and code.
Working name "Photo Swipe"; the App Store name is still Warren's call. Repo `warrenlimzf/photo-swipe`.

## Layout
| Path | What |
|---|---|
| `Sources/SwipeCore/` | Pure logic: decisions, session + undo, month grouping, On This Day, streak, save file. No UI, no Photos. |
| `Sources/PhotoSwipeUI/` | Every screen (SwiftUI) + `PhotoLibrary.swift`, the only file that touches PhotoKit. |
| `App/` | The `@main` entry point only. |
| `Tests/SwipeCoreTests/` | Swift Testing tests for SwipeCore. |
| `PhotoSwipe.xcodeproj/` | Hand-written Xcode project (bundle id, Info.plist keys, signing). The source of truth; committed. |
| `project.yml` | Unused XcodeGen equivalent of the project, kept for reference. |
| `App/Assets.xcassets` + `tools/make_icon.py` | App icon and the script that draws it. |
| `site/` | The marketing landing page (one static `index.html`, relative paths; GSAP 3.12.5 + ScrollTrigger + Lenis 1.1.13 from CDN; few words, motion first, detail goes in the README). `img/photos/` = 21 shots from the simulator set (his own photos, no wallpapers); `img/v16-*.jpg` = v1.6 tangerine screens (months, swipe, review, Golf album; never the "Girlfriend" album). Page look = the app's Theme tokens (light page, orange hero panel, drawn phone shows the v1.6 swipe screen); old `v13-*`/black shots are unused. Verify at 10 sizes before shipping (memory `marketing-pages-few-words`). Vercel project `photo-swipe`, served at warrenlimzf.com/photo-swipe through a rewrite in `1.0 - personal website/vercel.json` to `photo-swipe-three.vercel.app` (`photo-swipe.vercel.app` belongs to someone else). Deploy: `cd site && vercel deploy --prod --yes --scope warrenlimzf-projects`. |
| `README.md`, `LICENSE`, `docs/screenshots/` | Public face of the repo: install guide, safety notes, MIT. Screenshots use Warren's own published gallery photos, never Apple wallpapers. |
| `install-local.sh` | Gitignored. Signs with his team and installs on his iPhone. The only place his Team ID and device ID live; keep both out of tracked files. |
| `docs/spec.md` | Feature spec, research on the original, App Store checklist. |

## Commands
- Tests: `./test.sh`
- Type-check all screens on the Mac: `swift build`
- iPhone build: `xcodebuild -project PhotoSwipe.xcodeproj -scheme PhotoSwipe -destination "generic/platform=iOS Simulator" -derivedDataPath build CODE_SIGNING_ALLOWED=NO build`

## Invariants
- **Never delete a photo without the review grid and the iOS system prompt.** Swipes only record intent.
- **Photos never leave the phone.** No network code, no analytics, no accounts. The App Store privacy label is "Data Not Collected"; adding any SDK changes that.
- **Do not copy Swipewipe's name, icon, screenshots or wording.** App Store guideline 4.1 rejects copycats.
- Logic goes in SwipeCore with a test first; views stay thin.
- **Album code only adds/removes album membership, never deletes a photo.** The rail starts empty; Reset progress keeps albums. Album writes go through `AppModel.enqueue` (in order); `refreshAlbums()` waits for that queue, and code running inside the queue must call `loadAlbumMembers()` instead or it waits on itself.
- **Never `git add -A` here.** Xcode writes `DEVELOPMENT_TEAM` (Warren's Team ID) into `project.pbxproj` on his Mac when he picks a team. Keep it in his working copy so Run works, and strip those lines from anything staged.
- **Shipping a change to users = a GitHub Release.** Nobody's phone updates itself, and README readers are told to Watch → Releases. After pushing a user-visible change: bump `MARKETING_VERSION` in the project, then `gh release create vX.Y.Z --title ... --notes ...` with a short what-changed note. First release: v1.0.0 (2026-10-14).
- **Swipes never block.** `decide()` records the verdict at once and hands the old card to `FlyingCard` to finish its exit; do not go back to waiting on an animation before the next card is live. The blurred backdrop is its own `Equatable` view so a drag does not redraw it.
- macOS `#if` branches in `Platform.swift` exist only so `swift build` works on the Mac. The product is iPhone only.
- **Look = Foodie, colours chosen by the user (Warren, 15 Oct 2026; replaced the black "Gallery" look).** Off-white page, white cards with big radii and soft shadows (no borders). One gradient family at a time does all the work (hero, buttons, progress, selection), and the user picks it in ⋯ → Colours: `Palette.swift` holds six (Tangerine default, Sunset, Aurora, Ocean, Berry, Midnight), each a 3×3 `MeshGradient` that drifts (`HeroFill`, the native take on React Bits' Aurora; "Moving colours" switch, still under Reduce Motion) plus four accent shades, and a matching alternate app icon (`tools/make_icon.py` draws all six; names listed in `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`). Never hard-code a brand colour: go through `Theme.b700/b500/b300/b100`, `Theme.cta`, `HeroFill`. Green and red only mean keep / delete in every palette. Every screen starts with the hero (`HeroShape`): big on Library with the self-swiping `PrintStack`, `CompactHero` on pushed screens, a short band on the swipe screen. Pills for primary actions, SF Rounded for figures and headings, labels not sentences. Every button buzzes (`PressStyle` → `Haptics.press`), verdicts thud. Status bar stays white: root `preferredColorScheme(.dark)` + light environment, `StatusScrim` after scrolling, swipe cover hides it. Shared pieces in `Brand.swift`.
- Test with real photographs, never generated gradient images: blobs make any layout look AI-made. `tools/` holds the icon script; the simulator photo set is rebuilt from macOS wallpapers.

Emoji albums shipped in v1.1.0 (plan `docs/superpowers/plans/2026-10-14-emoji-albums.md`). v1.3.0 (14 Oct): Library has a To do / Done switch (finished months move to Done, nothing is greyed out); album rows show emoji then name. README is split into First install / Your two Xcode settings / Update / 7-day renewal / Wi-Fi; `install-local.sh` also works over Wi-Fi once paired.
v1.4.0 (15 Oct): rail is single-select and filing moves a photo out of other rail albums (undo restores); hold-drag reorders the rail; the swipe screen has `interactiveDismissDisabled()` so only the close button leaves.
v1.7.1 (15 Oct): every swipe card is the same 3:4 portrait rectangle, so drags anywhere on it swipe; landscape media sits over a blurred copy, video is a bare player layer (no AVKit controls). v1.7.0 (15 Oct): six user-chosen gradient palettes with drifting mesh hero and matching app icons. v1.6.0 (15 Oct): Foodie restyle in tangerine, new icon. v1.5.0 (15 Oct): Library opens on Albums, then the to-delete row, then months; the Freed/Reviewed/Streak summary was removed (it lives in Stats); finished months carry a big green tick over the mosaic; progress bars thicker (6pt months, 5pt deck).
State and next steps: `SESSION_HANDOFF.md`.
