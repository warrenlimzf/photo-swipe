<p align="center"><img src="docs/screenshots/icon.png" width="96" alt="Photo Swipe icon"></p>

# 📸 Photo Swipe

> **Clear out your camera roll by swiping. Right keeps a photo, left bins it, and nothing is deleted until you've looked over the pile.**
> Free, no ads, no account, no subscription. **Your photos never leave your phone.**

[![Platform: iOS 18+](https://img.shields.io/badge/platform-iOS%2018%2B-0ea5e9)](#-install-step-by-step)
[![Built with SwiftUI](https://img.shields.io/badge/built%20with-SwiftUI-f05138)](#-how-it-was-built)
[![Privacy: 100% on device](https://img.shields.io/badge/privacy-100%25%20on%20device-22c55e)](#-is-it-safe)
[![Updates: watch releases](https://img.shields.io/badge/updates-watch%20releases-f59e0b)](#-getting-updates)
[![License: MIT](https://img.shields.io/badge/license-MIT-8b5cf6)](LICENSE)
[![Case study](https://img.shields.io/badge/case%20study-warrenlimzf.com-3FB950)](https://www.warrenlimzf.com/photo-swipe/)

<p align="center">
  <img src="docs/screenshots/library.jpg" width="23%" alt="Library, month by month">
  <img src="docs/screenshots/months.jpg" width="23%" alt="A month shown as a mosaic of its photos">
  <img src="docs/screenshots/swipe.jpg" width="23%" alt="Swiping through a month">
  <img src="docs/screenshots/review.jpg" width="23%" alt="Reviewing photos before they are deleted">
</p>

---

## ⏱️ 30-second version

| | |
|---|---|
| **What is it?** | An iPhone app that shows your photos one at a time so you can keep or bin each with a swipe. |
| **What does it cost?** | Nothing. No ads, no sign-up, no swipe limit. |
| **Can I just download it to my iPhone?** | ❌ No. It is not on the App Store. You build it yourself with a **Mac**, for free. [Why ⬇️](#-read-this-first-it-is-not-on-the-app-store) |
| **I already have it. How do I update?** | One Terminal line, re-enter two Xcode settings, press Run. [Update ⬇️](#-update-to-a-new-version) |
| **How long does setup take?** | About 30 minutes the first time, mostly waiting for Xcode to download. |
| **Is it safe for my photos?** | Yes. It never goes online and cannot delete without your confirmation. [Details](#-is-it-safe) |
| **How do I hear about new versions?** | 🔔 Click **Watch** on this page. It is the only way. [How](#-getting-updates) |

---

## 📖 Table of contents

1. [What it does (and doesn't)](#-what-it-does-and-doesnt)
2. [Read this first: it is not on the App Store](#-read-this-first-it-is-not-on-the-app-store)
3. [📲 Install, step by step](#-install-step-by-step) (first time)
4. [🪪 Your two Xcode settings](#-your-two-xcode-settings) (every install and update)
5. [🔔 Getting updates](#-getting-updates)
6. [🔄 Update to a new version](#-update-to-a-new-version) (already installed)
7. [🔁 The 7-day renewal](#-the-7-day-renewal) (already installed)
8. [Is it safe?](#-is-it-safe)
9. [How it works](#-how-it-works)
10. [How it was built](#-how-it-was-built)
11. [Troubleshooting](#-troubleshooting)
12. [For developers and AI assistants](#-for-developers-and-ai-assistants)
13. [Credit and licence](#-credit-and-licence)

---

## 🧭 What it does (and doesn't)

**✅ This IS:**
- 👉 **Swipe to sort.** Right keeps, left marks for deletion. There are buttons too.
- ↩️ **Undo.** Step back as many swipes as you like.
- 🗓️ **Month by month.** Your library is split into months, each with a line of progress. Finished months get a tick.
- 🕰️ **On this day.** Photos from today's date in earlier years.
- 🧺 **A review pile.** Marked photos wait in a grid. Tap one to rescue it.
- 🔖 **Bookmarks** for photos you can't decide on yet.
- 📁 **Emoji albums.** Tap ＋ under the photo on the swipe screen to make one, like ✈️ Trips. Tap the emoji, swipe right, and the photo lands in that album in Apple Photos. Undo takes it back out. Open an album to **Select** photos and favourite them, move them to another album, take them out or delete them. (Shared iCloud albums aren't possible: Apple gives apps no access to them.)
- 🎉 **A finish screen** for every month: the tick draws itself, your album emojis burst out, and **Next** takes you straight to the following month.
- 📊 **Stats:** space freed, photos kept and deleted, and a daily streak.

**❌ This is NOT:**
- Not an App Store app. You cannot install it by tapping a link.
- Not a cloud service. There is no server, no account and no upload.
- Not a silent deleter. A swipe only marks a photo. Deleting takes your tap and then Apple's own confirmation.
- Not tested on hundreds of phones. It has been used on one person's iPhone, so go gently the first time.

---

## 🚧 Read this first: it is not on the App Store

Apple only lets apps install with one tap if they come through the App Store, which costs the developer US$99 a year. I haven't paid that, so this app reaches a phone a different way: **you build your own copy from this code.** It is free, but it needs a Mac.

| You have | Can you install it? |
|---|---|
| 💻📱 A Mac and an iPhone | ✅ Yes. Follow the steps below. |
| 📱 An iPhone but no Mac | ❌ No. There is no way to put it on the phone without a Mac. |
| 🪟 A Windows PC | ❌ No. Xcode, Apple's tool for building iPhone apps, only runs on a Mac. |
| 💻 A Mac only | 🟡 You can try it in the iPhone Simulator, but it is built for the phone. |

### 🚦 Which guide do you need?

| Your situation | Go to | Takes |
|---|---|---|
| 🆕 Never installed it before | [Install, step by step](#-install-step-by-step) | ~30 min, once |
| 📬 Already have it, got a release email | [Update to a new version](#-update-to-a-new-version) | ~3 min |
| ⏰ Already have it, it stopped opening | [The 7-day renewal](#-the-7-day-renewal) | ~1 min |

> ⏳ **Two things to expect on this free route.** The app **stops opening after 7 days** and has to be renewed from your Mac ([how](#-the-7-day-renewal)). And it **does not update itself**: you only hear about new versions if you [watch this repo](#-getting-updates).

---

## 📲 Install, step by step

**You need:** a Mac with about 20 GB free, an iPhone on iOS 18 or later with its cable, and a free Apple ID (the one you already use is fine).

### 1️⃣ Watch this repo (required)
At the top of this page click **Watch → Custom → tick Releases → Apply**. You need a free GitHub account for this.

> 🔔 **Do not skip this.** There is no App Store to push updates to your phone. A release email from GitHub is the only way you will ever hear about a fix or a new version.

### 2️⃣ Install Xcode
Open the **App Store on your Mac**, search for **Xcode**, and install it. It is made by Apple and it is free. It's a large download. Open it once, accept the licence, and when it offers platforms, keep **iOS** ticked.

### 3️⃣ Sign in to Xcode with your Apple ID
Menu bar: **Xcode → Settings → Apple Accounts**, click **+**, and sign in. You are typing into Apple's own software. This project never sees your password.

### 4️⃣ Download the code
Open **Terminal** (press **Cmd-Space**, type *Terminal*, press Return), paste this line, and press Return:

```bash
cd ~ && (git clone https://github.com/warrenlimzf/photo-swipe.git 2>/dev/null || (cd photo-swipe && git fetch && git reset --hard @{u})) && open ~/photo-swipe/PhotoSwipe.xcodeproj
```

It downloads the code and opens the project in Xcode. Keep this line somewhere: the same line is how you [update](#-update-to-a-new-version) later.

> 📁 **Where it's saved:** a folder called **`photo-swipe`** in your home folder, `/Users/<your Mac username>/photo-swipe`. Terminal shows this as `~/photo-swipe`. In Finder, press **Shift-Cmd-H** to open your home folder and you'll see it. The project file inside is **`PhotoSwipe.xcodeproj`**: double-click it any time to reopen the project.

> 💡 **Rather not use Terminal?** Click the green **Code** button on this page, then **Download ZIP**. Unzip it (it lands in **Downloads** as `photo-swipe-main`) and double-click **`PhotoSwipe.xcodeproj`** inside.

### 5️⃣ Change the Team and the Bundle Identifier
Do [these two settings](#-your-two-xcode-settings) now. Without them the build fails with red errors.

### 6️⃣ Connect your iPhone
Plug it in, unlock it, and tap **Trust** when it asks.

### 7️⃣ Turn on Developer Mode
On the iPhone: **Settings → Privacy & Security → Developer Mode**. Switch it on, restart when asked, then confirm.

### 8️⃣ Press Run
At the top of the Xcode window, pick your iPhone from the device menu, then press the **Run** button (the triangle ▶).

> 🔑 Your Mac may ask for your **Mac login password** (not your Apple ID password) so Xcode can use your signing key. Type it and choose **Always Allow**.

### 9️⃣ Trust yourself on the iPhone, then allow photos
The app installs but won't open yet. Xcode shows **"The application could not be launched because the Developer App Certificate is not trusted"** and the phone says **"Untrusted Developer"**. That's expected: your iPhone just hasn't been told to trust apps you built yourself.

1. Click **OK** on the Xcode message.
2. On the iPhone: **Settings → General → VPN & Device Management**.
3. Under **Developer App**, tap your Apple ID email, then **Trust "…"**, then **Trust** again.
4. Open Photo Swipe from the home screen (or press **Run** again). When it asks about photos, choose **Allow Full Access**.

> ✅ You only trust yourself once per Apple ID. Updates and weekly renewals open straight away.

> 🖼️ With limited access the app only sees the handful of photos you hand-pick, which defeats the point.

🎉 **Done.** From now on you only ever [renew](#-the-7-day-renewal) (weekly) or [update](#-update-to-a-new-version) (when a release email arrives).

**To remove it later:** press and hold the icon and choose **Remove App**, like any other app.

---

## 🪪 Your two Xcode settings

**When:** after the first download, and again after **every** update. Each download puts both settings back to mine, so they have to be changed every time new code arrives. (A weekly [renewal](#-the-7-day-renewal) downloads nothing, so it keeps your settings.)

**Where:** in Xcode's left sidebar click the blue **PhotoSwipe** icon at the top. In the middle, under **TARGETS**, click **PhotoSwipe**, then open the **Signing & Capabilities** tab.

| Setting | Change it to |
|---|---|
| **Team** | Your own name, shown as **"Your Name (Personal Team)"** |
| **Bundle Identifier** | Replace `com.warrenlimzf.photoswipe` with your own, like **`com.yourname.photoswipe`**. Lowercase letters, numbers and dots only, no spaces. |

> ⚠️ **Skip the Bundle Identifier and the build fails.** An app ID can only belong to one Apple account, and `com.warrenlimzf.photoswipe` is mine. Keep it and Xcode shows two red errors: **"Failed Registering Bundle Identifier … is not available"** and **"No profiles for 'com.warrenlimzf.photoswipe' were found"**. Type your own ID and both disappear (click **Try Again** if they don't clear by themselves).

> 🔁 **Use the same ID every time.** A different ID installs a second, separate app, and your progress stays behind in the old one. Write yours down somewhere.

---

## 🔔 Getting updates

**This app cannot update itself.** Automatic updates are an App Store feature, and this is not in the App Store. The copy on your phone stays exactly as it was the day you built it until you rebuild it.

### How to be told when there is a new version
1. Sign in to GitHub (a free account is enough).
2. At the top of this page click **Watch**.
3. Choose **Custom**, tick **Releases**, and click **Apply**.

GitHub will now email you each time a new version is published, with a short note on what changed. Choosing "Releases" only means you get one email per version, not one for every small edit.

Prefer not to make an account? Bookmark the [Releases page](https://github.com/warrenlimzf/photo-swipe/releases) and check it now and then.

---

## 🔄 Update to a new version

**For you if:** Photo Swipe is already on your phone and a release email arrived. No need to sign in or trust anything again.

1. **Get the new code.** Paste the same line into **Terminal** again:

   ```bash
   cd ~ && (git clone https://github.com/warrenlimzf/photo-swipe.git 2>/dev/null || (cd photo-swipe && git fetch && git reset --hard @{u})) && open ~/photo-swipe/PhotoSwipe.xcodeproj
   ```

   This time it replaces your `~/photo-swipe` folder with the latest version and opens Xcode.
   *Used the ZIP?* Download the new ZIP instead and open its `PhotoSwipe.xcodeproj`.
2. **Change the Team and the Bundle Identifier again.** The download reset them to mine. Use the [same ID as last time](#-your-two-xcode-settings).
3. **Plug in the iPhone (or use [Wi-Fi](#-skip-the-cable-install-over-wi-fi)) and press Run ▶.**

> ✅ **Your progress is kept.** Installing over the app that's already on your phone keeps your decisions, bookmarks and stats. Only deleting the app first wipes them.

> 💡 Saw `fatal: destination path 'photo-swipe' already exists`? That came from typing plain `git clone`. It means the code is already on your Mac. Use the line above, which updates the folder instead.

---

## 🔁 The 7-day renewal

**For you if:** the app has stopped opening. An app installed with a free Apple ID stops opening after 7 days. That is Apple's limit, not a fault. The icon stays and your data stays.

1. Double-click **`PhotoSwipe.xcodeproj`** in your `photo-swipe` folder (or pick it from Xcode's **File → Open Recent**).
2. Plug in the iPhone (or use Wi-Fi) and press **Run ▶**.

That's it, about a minute. Nothing is downloaded, so your Team and Bundle Identifier are still set.

> 💡 You have to renew every week anyway, so the easy habit is: check for a release email first. If there is one, [update](#-update-to-a-new-version) instead, which renews at the same time.

### 📶 Skip the cable: install over Wi-Fi

You only need the cable once. After that, renewing and updating can happen over Wi-Fi.

1. With the iPhone plugged in, open **Window → Devices and Simulators** in Xcode.
2. Click your iPhone in the list and tick **Connect via network**.
3. Unplug it. From now on, keep the Mac and iPhone on the **same Wi-Fi**, unlock the phone, pick it at the top of Xcode and press **Run**.

> 💡 This is the same install as with the cable, just without the wire. If the phone shows as "not connected", unlock it and check both are on the same network. The first wireless install can take a little longer.

---

## 🔒 Is it safe?

You are being asked to run a stranger's code against your photo library, so here is what it does and how to check for yourself.

| Question | Answer | How to verify |
|---|---|---|
| 🌐 Can it send my photos anywhere? | **No.** There is no networking code in the app. | Search the `Sources` folder for `URLSession` or `http`: zero results. |
| 📦 Does it include other people's code? | **No.** Only Apple's own frameworks. | `Package.swift` lists zero dependencies. |
| 🗑️ Can it delete without asking? | **No.** You tap Review, then Delete, then iOS shows its own confirmation, which no app can skip. | Read `PhotoLibrary.swift`: it is the only file that touches your library. |
| ♻️ Can I get a deleted photo back? | **Yes,** for 30 days. | They go to **Recently Deleted** in the Photos app. |
| 📝 What does it store? | One small file of your decisions, bookmarks and stats, on the phone. No copies of photos. | `StateFile` in `Sources/SwipeCore`. |
| 🪪 Does it see my Apple ID? | **No.** You sign in to Xcode, which is Apple's software. | Nothing in this repo handles accounts. |
| 👤 Accounts, ads, analytics? | **None.** | Same search as the first row. |

> ⚠️ **Honest limits.** It has been used on one person's phone, not tested across many devices. Check the review grid before you confirm a delete. It comes with no warranty (see the licence).

---

## 🔍 How it works

```
 Your photo library                         One small file on your phone
        │                                              ▲
        ▼                                              │
  PhotoLibrary.swift ──► screens (SwiftUI) ──► rules (SwipeCore) ──► decisions,
  the only file that      library, swipe card,   keep / delete, undo,   bookmarks,
  touches your photos     review grid, stats     months, streak         stats
```

1. **The library** reads your photos through Apple's PhotoKit and groups them by month.
2. **Swiping** records "keep" or "delete" for that photo. Nothing in your library changes yet.
3. **The review grid** shows everything marked for deletion. A tap rescues a photo.
4. **Delete** hands the list to iOS, which asks you to confirm and then moves the photos to Recently Deleted.

A swipe counts the instant you let go. The old card flies off on its own while the next one is already live, so there is never a wait between photos.

---

## 🧰 How it was built

I'm a finance student, not a software engineer. I wrote the brief, made the design calls and tested it on my own phone. **[Claude Code](https://claude.com/claude-code) wrote the Swift.** The first design was thrown out for looking machine-made. The current look, black with the photos edge to edge, was the second attempt. The full story is in the [case study](https://www.warrenlimzf.com/photo-swipe/).

| Piece | What it is |
|---|---|
| 🧡 **Swift** | Apple's programming language |
| 🖼️ **SwiftUI** | Apple's toolkit for screens, animation and gestures |
| 📷 **PhotoKit** | Apple's framework for reading and deleting from the photo library |
| 🔨 **Xcode** | Apple's app that turns the code into something an iPhone can run |
| ✅ **Swift Testing** | 11 automated tests for the swipe, undo, month grouping and streak rules |

---

## 🧯 Troubleshooting

| What you see | What to do |
|---|---|
| **"Untrusted Developer"** when opening the app | iPhone: **Settings → General → VPN & Device Management**, tap your Apple ID, **Trust**. Step 9 of the [install](#-install-step-by-step). |
| **The app won't open after about a week** | The 7-day limit. Open the project, plug in and press **Run** again. [The 7-day renewal](#-the-7-day-renewal) |
| **"Signing requires a development team"** | Pick your name under **Team**. [Your two Xcode settings](#-your-two-xcode-settings) |
| **"Failed Registering Bundle Identifier"** or **"No profiles for 'com.warrenlimzf.photoswipe' were found"** | That ID is mine, and every download (first install or update) resets it. Change **Bundle Identifier** to your own, like `com.yourname.photoswipe`, then **Try Again**. [Your two Xcode settings](#-your-two-xcode-settings) |
| **"Developer App Certificate is not trusted"** on your Mac | Normal on the very first install. Click **OK**, then trust yourself on the iPhone: step 9 of the [install](#-install-step-by-step). |
| **`fatal: destination path 'photo-swipe' already exists`** in Terminal | The code is already on your Mac (in `~/photo-swipe`). Use the one-line command from [Update to a new version](#-update-to-a-new-version), which updates that folder. |
| **A second Photo Swipe icon appeared, or your progress is gone after an update** | You used a different Bundle Identifier from last time. Set it back to your old one and **Run** again. [Your two Xcode settings](#-your-two-xcode-settings) |
| **The app's photo message mentions only "keep and delete"** | You have an old copy. [Update to a new version](#-update-to-a-new-version). Your progress is kept. |
| **A box asks for a password to allow `codesign`** | It wants your **Mac login password**. Type it and click **Always Allow**. |
| **Developer Mode is not in Settings** | It appears after the phone has been connected to Xcode once. Plug in, open Xcode, then look again. |
| **The app only shows a few photos** | Photo access is limited. iPhone: **Settings → Apps → Photo Swipe → Photos → Full Access**. |
| **Your iPhone is not in Xcode's device menu** | Unlock the phone, tap **Trust**, and try a different cable or port. |
| **Xcode says the iPhone is "not connected"** | Plug it in, or set up [Wi-Fi installs](#-skip-the-cable-install-over-wi-fi). Over Wi-Fi the phone must be unlocked and on the same network as the Mac. |
| **The build fails right after an iOS update** | Update Xcode from the Mac App Store, then press Run again. |

Still stuck? [Open an issue](https://github.com/warrenlimzf/photo-swipe/issues) and say what you saw.

---

## 💻 For developers and AI assistants

```
Sources/SwipeCore/      rules only: decisions, session + undo, months, On this day, streak, save file
Sources/PhotoSwipeUI/   every screen (SwiftUI); PhotoLibrary.swift is the only file that touches PhotoKit
App/                    the @main entry point and the icon
Tests/SwipeCoreTests/   Swift Testing tests for SwipeCore
site/                   the case-study page (static HTML)
```

Run the tests on a Mac with Xcode installed:

```bash
./test.sh
```

Build for the simulator from the command line:

```bash
xcodebuild -project PhotoSwipe.xcodeproj -scheme PhotoSwipe -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build
```

House rules, if you change it: rules go in `SwipeCore` with a test first, swipes must never wait on an animation, and nothing may add networking. `CLAUDE.md` has the rest.

---

## 📜 Credit and licence

The idea of sorting photos by swiping is not mine. Several App Store apps do it, and this was built after trying one of them. The code, design and icon here were made from scratch and share nothing with those apps.

Released under the [MIT licence](LICENSE): use it, change it, share it, as long as the notice stays.

<sub>Built by <a href="https://www.warrenlimzf.com/">Warren Lim</a> with Claude Code.</sub>
