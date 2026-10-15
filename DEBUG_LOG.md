# Debug log

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
