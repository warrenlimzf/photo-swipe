#!/bin/bash
# sim-driver: drives the installed Photo Swipe app on a simulator with XCUITest, for marketing
# screenshots (Xcode 27 has no Simulator.app window to click). Not part of the app.
#  1. xcrun simctl boot <udid>; xcrun simctl launch <udid> com.warrenlimzf.photoswipe
#  2. Build once: xcodebuild build-for-testing -project tools/sim-driver/Driver.xcodeproj -scheme Driver \
#       -destination id=<udid> -derivedDataPath /private/tmp/photoswipe-sim-driver/dd
#  3. Same flags with test-without-building, run in the background (the test loops on $IO/cmd).
#  4. Send commands with this script; each call saves $IO/shot.png. "quit" ends the run.
#  Mid-drag shot: (sleep 2.4; xcrun simctl io <udid> screenshot out.png) & c.sh "drag 200 400 285 400 0.1 150 3.5"
# Send driver commands, wait for them, then screenshot the sim to $IO/shot.png.
# Usage: tools/sim-driver/c.sh "tap 200 437" "sleep 1.5"
# Commands (points, 402x874 screen): tap x y | long x y secs | drag x1 y1 x2 y2 [press] [velocity] [hold] | sleep s | tree | quit
IO=/private/tmp/photoswipe-sim-driver; UDID=${UDID:-D93744A5-F200-4A0A-8B65-A10D7AF30767}
mkdir -p $IO; N=$(date +%s%N)
{ echo $N; for a in "$@"; do echo "$a"; done; } > $IO/cmd.tmp && mv $IO/cmd.tmp $IO/cmd
for i in $(seq 1 600); do grep -q "^$N" $IO/done 2>/dev/null && break; perl -e 'select(undef,undef,undef,0.2)'; done
head -c 300 $IO/done; echo
perl -e 'select(undef,undef,undef,0.6)'
xcrun simctl io $UDID screenshot $IO/shot.png >/dev/null 2>&1
