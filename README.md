# InstantFocus

A tiny macOS menu bar app: give each app a shortcut, press it, and you're in that app,
whether its window is on the current Space, another Space, or full screen. No slide, no
crossfade. That's all it does: trackpad swipes and other Space switching stay as macOS has them.

The menu bar shows the focused app's icon when that app has a shortcut, otherwise ⚡,
drawn black on white or white on black (your choice in Settings). Click it, or press
**⌘⇧Space** (changeable in Settings), for a list of your apps: ↑ ↓ to move, Return or Space
to pick, Esc to close. Picking an app jumps to it the same instant way. The list follows the
order of the apps in Settings (reorder them with ▲ ▼).

## Install

Requires macOS 13 or later (Apple Silicon or Intel).

**Homebrew**

```sh
brew install --cask vasilgen/tap/instantfocus
```

If Homebrew says the tap isn't trusted, run `brew trust --cask vasilgen/tap/instantfocus` and try again.

**Download:** grab `InstantFocus-<version>.zip` from
[Releases](https://github.com/vasilgen/instant-focus/releases), unzip it, and move
`InstantFocus.app` to Applications.

### First launch

InstantFocus isn't signed with an Apple Developer ID, so macOS warns you the first time
("Apple could not verify InstantFocus is free of malware", or "can't be opened because the
developer cannot be verified"):

1. Open it once and dismiss the warning.
2. Go to System Settings → Privacy & Security, scroll down, and click **Open Anyway** next to InstantFocus.
   (Or, in Terminal: `xattr -dr com.apple.quarantine /Applications/InstantFocus.app`.)
3. When asked, allow InstantFocus under **Accessibility**: shortcuts and switching need it.
   After an update, macOS may ask again.

Then add your apps and their shortcuts in the Settings window that opens.

## How it works

1. A keyboard event tap catches your shortcut.
2. InstantFocus finds which Space holds the app's frontmost window, using the private
   `CGSCopySpacesForWindows` / `CGSCopyManagedDisplaySpaces` calls.
3. If that Space isn't showing, it switches there with InstantSpaceSwitcher's trick: a synthetic
   trackpad swipe with a huge velocity, so the Dock skips the animation. No SIP changes.
   With two displays, the cursor is moved onto the target display first, because ISS acts on the
   display under the cursor.
4. Once the Space is on screen, the app is activated (like `open -a`). Nothing is left to animate.

## Build from source

Requires Xcode (or the Command Line Tools).

```sh
scripts/build.sh --install    # build, ad-hoc sign, replace /Applications/InstantFocus.app, launch
```

Each rebuild changes the ad-hoc signature, so macOS forgets the Accessibility permission;
the app clears the stale entry and asks again.

Settings live in `defaults read io.github.vasilgen.InstantFocus` (`shortcuts` is a JSON string).

**Releasing:** `scripts/release.sh <version>` stamps the version, tags and pushes, builds a
universal app, publishes it on GitHub Releases, and updates the cask in
[vasilgen/homebrew-tap](https://github.com/vasilgen/homebrew-tap).

## Layout

| Path | What |
| --- | --- |
| `Sources/InstantFocus/` | The app (Swift): `Focuser` (switch + activate), `Spaces` (window → Space lookup), `HotKeys` (event tap), `MenuBarIcon`, `Store` (settings), SwiftUI settings window |
| `Sources/ISS/` | InstantSpaceSwitcher's core C code, vendored **unmodified** (MIT, see `Sources/ISS/LICENSE`) |
| `scripts/vendor-iss.sh [tag]` | Re-copy ISS's core at a given release tag (current one in `Sources/ISS/VERSION`) |
| `scripts/build.sh`, `scripts/release.sh` | Build/install locally; publish a release |

## Will it keep working across macOS updates?

- **Public APIs (stable):** event taps, Accessibility, window list, app activation, launch at login.
- **Private APIs (can break):** the Space lookup calls, and the synthetic Dock swipe ISS uses to
  switch. Apple has changed swipe handling before; ISS v3.1 already carries macOS 27 fixes. If an
  update breaks switching, update the vendored copy with `scripts/vendor-iss.sh <newer tag>` and rebuild.
- **Failing soft:** the private Space calls are looked up at runtime, not linked, so if one
  disappears the app still launches. Shortcuts still focus the app, with macOS's normal animation.

## Credits

- **[InstantSpaceSwitcher](https://github.com/jurplel/InstantSpaceSwitcher)** by jurplel (MIT):
  the instant-switch technique. Its core C code is included as-is in `Sources/ISS`. Also the
  inspiration for the settings window and for resetting a stale Accessibility entry before prompting.
- **[yabai](https://github.com/asmvik/yabai)**: inspiration for mapping windows to Spaces with
  the private SkyLight/CGS calls. No code copied.
- **[skhd](https://github.com/asmvik/skhd)**: the `⌥1 → open -a App` workflow this replaces, and
  the event-tap approach to global hotkeys. No code copied.
- ⚡ is the `bolt` SF Symbol.

## License

MIT, see [LICENSE](LICENSE). `Sources/ISS` is InstantSpaceSwitcher's code under its own MIT license.
