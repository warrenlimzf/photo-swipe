# Photo Swipe — spec

Written 2026-10-14. Warren's brief: a one-to-one working equivalent of Swipewipe, published on the App Store, built without check-ins.

## What the original does (research, 2026-10-14)

Swipewipe ("Photo Cleaner: Swipewipe", App Store id1583884012, by MWM / Afternoon Products).

| Feature | In the original | In v1 here |
|---|---|---|
| Swipe right to keep, left to delete | Yes | Yes, plus buttons |
| Undo | Tap the current photo to go back one | Undo button (unlimited steps back within a session). Tap is left for video play |
| Month by month, crossed out when finished, progress wheel per month | Yes | Yes |
| On This Day | Top of the home screen | Yes |
| Bookmarks for "decide later" | Yes | Yes |
| Stats: photos reviewed, space saved | Yes | Yes, plus kept / deleted / library % |
| Streaks | Yes | Yes |
| Review before the real delete | Yes | Yes, tap to rescue |
| Hold for date and file info | Yes | Info button |
| Recents / Random decks | Yes | Yes, plus a Videos deck |
| Home-screen widget (On This Day) | Yes | Not in v1 |
| Daily reminder notification | Yes | Not in v1 |
| Themes | Yes | Not in v1 |
| Supercuts video, world map, AI enhance | Later additions | Not planned |
| Paywall | Subscription | None |

## Where this differs

The swipe-to-clean apps on the App Store are mostly paid by subscription. This one has no paywall, no ads and no swipe limit, and the photos stay on the phone.

## Screens

1. **Permission** — one explanation, one button. If access was denied, the button opens Settings.
2. **Library** — one line of figures (space freed, streak, reviewed count) over a thin progress line, a red row when photos are waiting to be deleted, an On This Day strip, then every month as an edge-to-edge mosaic of its newest photos with a hairline of progress. Finished months go grey with a green tick and can be reopened. Recents / Random / Videos, Bookmarks, Stats and Settings sit in the toolbar menu.
3. **Swipe deck** — the photo card with KEEP / DELETE stamps that fade in with the drag; delete, undo, info, bookmark and keep buttons; a trash counter that opens the review grid. Videos play inline.
4. **To delete** — grid of everything marked. Tap rescues a photo. One button deletes, iOS shows its own confirmation, and the photos go to Recently Deleted for 30 days.
5. **Bookmarks, Stats, Settings.**

## Emoji albums (v1.1.0)

- A rail of emoji buttons down the right of the swipe screen, ＋ at the bottom. It starts empty.
- ＋ asks for one emoji and a short name and makes a real album in Apple Photos titled "⛳ Golf".
- Tap an emoji to select it (green ring, name bubble for about a second). It stays on between photos and resets when the deck closes.
- Swipe right keeps the photo and adds it to every selected album. The Keep stamp shows the emojis. Deletes ignore the selection.
- Undo takes the photo out of only the albums that swipe added it to.
- Long-press an emoji: Edit (renames the Photos album) or Remove from rail (the Photos album stays).
- Home shows an Albums list; each album page can be swiped again, and a long-press removes a photo from the album.
- If the user deletes the album in Photos, the next right-swipe quietly recreates it.
- Shared iCloud albums are not possible (no API), and apps can open Photos but not a given album.

## Rules

- A swipe records intent only. Deleting needs the review grid plus the iOS prompt.
- Decisions, bookmarks and stats are saved to one JSON file in Application Support, keyed by photo identifier. Entries for photos that no longer exist are dropped on load.
- A deck opens on its undecided photos. If all are decided, it offers the whole stack again.
- No network code, no analytics, no account.
- iOS 18 or later, iPhone, portrait.

## App Store checklist

Needs Warren:
- [ ] Install Xcode from the Mac App Store (Apple ID sign-in).
- [ ] Apple Developer Program membership (US$99 a year, his Apple ID, his payment).
- [ ] Final app name and subtitle. "Swipewipe" and close variants are out.
- [ ] Pricing: free, one-time purchase, or subscription.

Claude can do after that:
- [ ] Generate the Xcode project, run on the simulator, fix what the iOS build turns up.
- [ ] App icon and screenshots.
- [ ] Privacy policy and support page (required URLs) at warrenlimzf.com/photo-swipe.
- [ ] App Store listing text, privacy label ("Data Not Collected"), age rating.
- [ ] Archive and upload. Warren presses Submit for Review.

## Known gaps

- Runs on the simulator only so far; never on a real phone.
- Undo on a month being re-reviewed clears the decision instead of restoring the old one.
- File sizes read `fileSize` from `PHAssetResource` by key, the common approach but not a documented property.
