# Debug log

## 2026-10-15 — dark clock on the orange hero (v1.6.0)
- Seen: after the Foodie restyle the status bar clock was black on the orange hero.
- Cause: the app forced `.preferredColorScheme(.light)`, which gives dark status bar text. iOS 27 also ignored `UIViewControllerBasedStatusBarAppearance = NO` for the full-screen swipe cover.
- Fix: root asks for `.preferredColorScheme(.dark)` while forcing `.environment(\.colorScheme, .light)` on the views; the swipe cover uses `statusBarHidden`; `StatusScrim` fades an orange strip behind the clock once the hero scrolls away.
- Don't retry: Info.plist status bar keys (global style), or a see-through nav bar on Library (its scroll-edge blur greys the hero).

## 2026-10-15 — stray swipe threw you out of a month (v1.4.0)
- Seen: a swipe or pinch outside the photo zoomed the swipe screen back to the calendar, losing the place.
- Cause: the deck is a `fullScreenCover` with `navigationTransition(.zoom)`, which gives iOS's interactive zoom-dismiss gesture for free.
- Fix: `.interactiveDismissDisabled()` on `SwipeDeckView` (covers all three places it opens). Only the X button leaves.
- Don't retry: adding a competing DragGesture to block it; the system gesture wins.

## 2026-10-15 — emoji drag felt laggy (v1.4.1)
- Seen: hold-and-drag on the album rail lagged, with a ghost left behind.
- Cause: system `onDrag`/`onDrop` (slow lift, faded placeholder, reorder only when crossing a drop target, contextMenu competing for the hold).
- Fix: custom `LongPressGesture(0.22s).sequenced(before: DragGesture)`; held emoji follows the finger un-animated, others shift by slot offsets, order committed once on release with animations off. Edit/Remove moved to a hold-without-moving dialog.
- Don't retry: system drag and drop for in-row reordering.

## 2026-10-15 — landscape photos and videos only swiped on the picture (v1.7.1)
- Seen: on a landscape photo or video, dragging in the space above or below the picture did nothing; once a video played, swipes on it could fail too.
- Cause: `CardView` took the photo's own aspect ratio, so a landscape card was a short strip and the band around it was empty page. The playing video was an AVKit `VideoPlayer`, which takes touches for its own controls.
- Fix: every card is one portrait rectangle (`cardRatio` 3:4) with `contentShape`; wider media sits fitted over a blurred copy of itself. Video plays in a bare `AVPlayerLayer` view with hit testing off; tapping the card pauses/resumes.
- Don't retry: AVKit `VideoPlayer` on the card (it eats drags), or sizing the card to the photo.
