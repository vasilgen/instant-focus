# Screenshots

## Generated

Rendered from the app's own drawing code. Don't edit them; after changing the icon,
re-run `scripts/render-icons.sh`.

| File | What |
| --- | --- |
| `icon-black-on-white.png`, `icon-white-on-black.png` | The ⚡ tile, 512 px |
| `menubar-light.png`, `menubar-dark.png` | The menu bar icon in both styles, on a light / dark menu bar |

## Captured

Retina (2×) captures; the README shows them at half width.

| File | Shot | Status |
| --- | --- | --- |
| `settings-dark.png` | The Settings window, Dark mode | ✓ in README |
| `app-list-dark.png` | The app list menu, Dark mode | ✓ in README |
| `settings-light.png`, `app-list-light.png` | The same in Light mode | To do (then the README can switch with the theme) |
| `demo.mp4` (or `demo.gif`) | ⌥2 into a full-screen app and back, 5–10 s | To do |

How:

- **Settings window:** ⌘⇧4, Space, click the window (⌥-click leaves out the shadow).
- **App list:** ⌘⇧Space, then ⌘⇧4 and drag over the icon and the list.
- **Demo:** ⌘⇧5 → Record Selected Portion, with KeyCastr showing the keys.

- Light and Dark: switch in System Settings → Appearance and take both.
- Clean screen: plain wallpaper, Do Not Disturb on, desktop icons hidden
  (`defaults write com.apple.finder CreateDesktop false; killall Finder`, `true` to undo),
  other menu bar items cropped out.
- ⌘⇧5 → Options: set **Save to** this folder and turn off **Show Floating Thumbnail**.
- Retina captures are 2× size: show them at half width (`<img width="…">`).
- Video to GIF: Gifski (`brew install --cask gifski`). Smaller MP4:
  `ffmpeg -i in.mov -vf "fps=30,scale=1280:-1" demo.mp4`.
