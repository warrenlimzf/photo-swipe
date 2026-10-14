#!/bin/bash
# Runs the logic tests. Needs Xcode selected (xcode-select -p).
cd "$(dirname "$0")" && swift test "$@"
