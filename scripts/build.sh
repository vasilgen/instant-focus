#!/bin/bash
# Build build/InstantFocus.app (release, ad-hoc signed).
#   scripts/build.sh              build for this Mac
#   scripts/build.sh --universal  build for Apple Silicon and Intel (what releases ship)
#   scripts/build.sh --install    also replace /Applications/InstantFocus.app and launch it
set -euo pipefail
cd "$(dirname "$0")/.."

ARCHS=()
[[ " $* " == *" --universal "* ]] && ARCHS=(--arch arm64 --arch x86_64)

swift build -c release ${ARCHS[@]+"${ARCHS[@]}"}
APP=build/InstantFocus.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release ${ARCHS[@]+"${ARCHS[@]}"} --show-bin-path)/InstantFocus" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ " $* " == *" --install "* ]]; then
  pkill -x InstantFocus && sleep 0.5 || true
  # Replace the contents, not the bundle folder: macOS's App Management protection
  # can refuse to delete an app folder in /Applications once it has been launched.
  rm -rf /Applications/InstantFocus.app/Contents
  ditto "$APP" /Applications/InstantFocus.app
  open /Applications/InstantFocus.app
  echo "Installed and launched /Applications/InstantFocus.app"
fi
