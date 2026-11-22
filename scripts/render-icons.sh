#!/bin/bash
# Render the menu bar icon artwork into docs/screenshots from the app's own drawing code.
# App icons come from the apps installed in /Applications (see scripts/render-icons.swift).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build docs/screenshots
swiftc -parse-as-library -O Sources/InstantFocus/MenuBarIcon.swift scripts/render-icons.swift -o build/render-icons
build/render-icons docs/screenshots
