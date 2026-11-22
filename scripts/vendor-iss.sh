#!/bin/bash
# Copy InstantSpaceSwitcher's core switching code (C, MIT) into Sources/ISS.
# The files are kept byte-for-byte; to upgrade, run with a newer tag and rebuild.
# Usage: scripts/vendor-iss.sh [tag]     (default: the tag in Sources/ISS/VERSION)
set -euo pipefail
cd "$(dirname "$0")/.."
TAG="${1:-$(cat Sources/ISS/VERSION 2>/dev/null || echo v3.1)}"
RAW="https://raw.githubusercontent.com/jurplel/InstantSpaceSwitcher/$TAG"
mkdir -p Sources/ISS/include
for f in ISS.c event_serialize.c event_serialize.h include/ISS.h; do
  curl -fsSL "$RAW/Sources/ISS/$f" -o "Sources/ISS/$f"
done
curl -fsSL "$RAW/LICENSE" -o Sources/ISS/LICENSE
echo "$TAG" > Sources/ISS/VERSION
echo "Vendored InstantSpaceSwitcher $TAG into Sources/ISS"
