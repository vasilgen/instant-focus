#!/bin/bash
# Publish a release: stamp the version, tag and push, build a universal app, upload it
# to GitHub Releases, and point the Homebrew cask (vasilgen/homebrew-tap) at it.
# Usage: scripts/release.sh 0.2.0
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:?usage: scripts/release.sh <version>}"
OWNER=vasilgen
REPO=instant-focus
# Run gh as $OWNER without switching the machine's active gh account.
export GH_TOKEN="$(gh auth token --user "$OWNER")"

[[ -z "$(git status --porcelain)" ]] || { echo "Commit or stash your changes first." >&2; exit 1; }

# Version → Info.plist → commit + tag → push
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" Resources/Info.plist
git diff --quiet || git commit -qam "Release $VERSION"
git tag "v$VERSION"
git push -q origin main "v$VERSION"

# Build → zip → GitHub release
scripts/build.sh --universal
ZIP="build/InstantFocus-$VERSION.zip"
ditto -c -k --keepParent build/InstantFocus.app "$ZIP"
gh release create "v$VERSION" "$ZIP" --repo "$OWNER/$REPO" --title "InstantFocus $VERSION" --generate-notes

# Homebrew cask
SHA256=$(shasum -a 256 "$ZIP" | cut -d' ' -f1)
CASK=$(cat <<EOF
cask "instantfocus" do
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/$OWNER/$REPO/releases/download/v#{version}/InstantFocus-#{version}.zip"
  name "InstantFocus"
  desc "Jump to any app with one shortcut, on any Space, without the animation"
  homepage "https://github.com/$OWNER/$REPO"

  depends_on macos: :ventura

  app "InstantFocus.app"

  uninstall quit: "io.github.vasilgen.InstantFocus"

  zap trash: "~/Library/Preferences/io.github.vasilgen.InstantFocus.plist"
end
EOF
)
CASK_PATH="repos/$OWNER/homebrew-tap/contents/Casks/instantfocus.rb"
OLD_SHA=$(gh api "$CASK_PATH" --jq .sha 2>/dev/null || true)
gh api -X PUT "$CASK_PATH" -f message="instantfocus $VERSION" -f content="$(printf '%s\n' "$CASK" | base64)" \
  ${OLD_SHA:+-f sha="$OLD_SHA"} --silent

echo "Released InstantFocus $VERSION: https://github.com/$OWNER/$REPO/releases/tag/v$VERSION"
