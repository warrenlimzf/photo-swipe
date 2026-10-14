<p align="center"><img src="docs/screenshots/icon.png" width="96" alt="Photo Swipe icon"></p>

# Photo Swipe

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform: iOS 18+](https://img.shields.io/badge/platform-iOS%2018%2B-black.svg)](#what-you-need)
[![Case study](https://img.shields.io/badge/case%20study-warrenlimzf.com-blue.svg)](https://www.warrenlimzf.com/photo-swipe/)

An iPhone app for clearing out your camera roll. It shows your photos one at a time: swipe right to keep one, left to bin it. Nothing is deleted until you look over the pile and confirm.

It is free, has no ads, no account and no subscription, and your photos never leave your phone.

<p align="center">
  <img src="docs/screenshots/library.jpg" width="23%" alt="Library, month by month">
  <img src="docs/screenshots/months.jpg" width="23%" alt="A month shown as a mosaic of its photos">
  <img src="docs/screenshots/swipe.jpg" width="23%" alt="Swiping through a month">
  <img src="docs/screenshots/review.jpg" width="23%" alt="Reviewing photos before they are deleted">
</p>

## What it does

- **Swipe to sort.** Right keeps, left marks for deletion. There are buttons too.
- **Undo.** Step back as many swipes as you like.
- **Month by month.** Your library is split into months, each with a progress line. Finished months are ticked off.
- **On this day.** Photos from today's date in earlier years.
- **Review before anything goes.** Marked photos wait in a grid. Tap one to rescue it.
- **Bookmarks** for photos you can't decide on yet.
- **Stats**: space freed, photos kept and deleted, and a daily streak.

## Read this first: it is not on the App Store

You can't install this by tapping a link on your iPhone. Apple only allows that for apps published through the App Store, which costs US$99 a year and I haven't done.

What you can do is build it yourself from this code. That is free, but it needs a Mac.

| You have | Can you install it? |
|---|---|
| A Mac and an iPhone | Yes. Follow the steps below. About 30 minutes the first time, mostly waiting for Xcode to download. |
| An iPhone but no Mac | No. There is no way to put it on the phone without a Mac. |
| A Windows PC | No. Xcode, Apple's tool for building iPhone apps, only runs on a Mac. |
| A Mac only | You can run it in the iPhone Simulator to try it, but it is built for the phone. |

Installed this way, the app **stops opening after 7 days**. That is Apple's limit on free accounts. Plug the phone in and press Run again to renew it. Your progress is kept.

## What you need

- A Mac with a recent macOS and about 20 GB free
- An iPhone on iOS 18 or later, and its cable
- A free Apple ID (the one you already use is fine)

## Install, step by step

**1. Get Xcode.** Open the App Store on your Mac, search for **Xcode**, and install it. It is made by Apple and it is free. It's a large download. Open it once, accept the licence, and when it offers platforms, keep **iOS** ticked.

**2. Get this code.** On this page click the green **Code** button, then **Download ZIP**, and unzip it. If you use git:

```bash
git clone https://github.com/warrenlimzf/photo-swipe.git
```

**3. Open the project.** In the folder, double-click **`PhotoSwipe.xcodeproj`**. Xcode opens.

**4. Sign in.** In the menu bar: **Xcode > Settings > Apple Accounts**, click **+**, and sign in with your Apple ID.

**5. Choose your team.** In the left sidebar click the blue **PhotoSwipe** icon at the top. In the middle, under TARGETS, click **PhotoSwipe**, open **Signing & Capabilities**, and pick your name in the **Team** menu (it says "Personal Team").

If Xcode complains that the bundle identifier is not available, change **Bundle Identifier** on the same screen to something of your own, like `com.yourname.photoswipe`.

**6. Connect your iPhone.** Plug it in, unlock it, and tap **Trust** when it asks.

**7. Turn on Developer Mode.** On the iPhone: **Settings > Privacy & Security > Developer Mode**, switch it on, restart when asked, then confirm.

**8. Run it.** At the top of the Xcode window, pick your iPhone from the device menu, then press the **Run** button (the triangle). The first time, your Mac asks for your **Mac login password** so Xcode can use the signing key. Type it and choose **Always Allow**.

**9. Trust yourself on the phone.** The first launch is blocked. On the iPhone go to **Settings > General > VPN & Device Management**, tap your Apple ID, then **Trust**. Open Photo Swipe again.

**10. Allow photos.** When the app asks, choose **Allow Full Access**. With limited access it only sees the photos you hand-pick.

To remove it later, press and hold the icon and choose **Remove App**, like any other app.

## Is it safe?

You are being asked to run a stranger's code against your photo library, so here is what it does and how to check.

- **It never connects to the internet.** There is no networking code in the app. You can confirm that by searching the `Sources` folder for `URLSession` or `http`: there are no results.
- **No accounts, analytics, ads or third-party code.** It uses only Apple's own frameworks. `Package.swift` lists zero dependencies.
- **It cannot delete silently.** Swiping only records what you want. To delete, you tap Review, then Delete, and then iOS shows its own confirmation that the app cannot skip.
- **Deleted photos are recoverable.** They go to **Recently Deleted** in the Photos app and stay there for 30 days.
- **What it saves:** one small file on your phone with your keep/delete decisions, bookmarks and stats. No photos are copied.
- **Your Apple ID.** You type it into Xcode, which is Apple's software. This project never sees it.

Honest limits: it has been used on one person's phone, not tested across many devices. Treat the first run gently and check the review grid before you confirm. It comes with no warranty (see the licence).

## How it was built

I'm a finance student, not a software engineer. I wrote the brief, made the design calls and tested it on my own phone. [Claude Code](https://claude.com/claude-code) wrote the Swift. The first design was thrown out for looking machine-made; the current look, black with the photos edge to edge, was the second attempt.

| Piece | What it is |
|---|---|
| **Swift** | Apple's programming language |
| **SwiftUI** | Apple's toolkit for screens, animation and gestures |
| **PhotoKit** | Apple's framework for reading and deleting from the photo library |
| **Xcode** | Apple's app that turns the code into something an iPhone can run |
| **Swift Testing** | 11 automated tests for the swipe, undo, month grouping and streak rules |

The code is in three parts:

- `Sources/SwipeCore` holds the rules (decisions, undo, months, streaks). It has no screens and never touches photos, so it can be tested on its own.
- `Sources/PhotoSwipeUI` holds every screen. `PhotoLibrary.swift` is the only file that talks to the photo library.
- `App` holds the entry point and the icon.

To run the tests on a Mac with Xcode installed:

```bash
./test.sh
```

## Credit and licence

The idea of sorting photos by swiping is not mine. Several App Store apps do it, and this was built after trying one of them. The code, design and icon here were made from scratch and share nothing with those apps.

Released under the [MIT licence](LICENSE): use it, change it, share it, as long as the notice stays.
