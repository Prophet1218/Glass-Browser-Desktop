# Glass Browser Desktop

A liquid glass web browser for **CachyOS / Arch Linux + KDE Plasma**, the desktop sibling of
[Glass Browser for Android](https://github.com/Prophet1218/Glass-Browser).

Built with **Qt 6 (QML) + Qt WebEngine (Chromium)**. The page content fills the whole window and the
glass bar floats above it: a fragment shader blurs and refracts whatever scrolls underneath in real time.

## Features
- Floating liquid glass bar – tabs on top, window controls (minimize / maximize / close) on the right,
  navigation + address capsule below
- Transparent window with KWin blur behind it, adjustable opacity
- Transparent web pages (Zen-style) with adjustable page background opacity
- Google sign-in, Google passwords, My Activity
- Private tabs, tab overview with *Close all*, session restore, reopen closed tab
- Address bar suggestions (Google + history + bookmarks), start page tiles, frequently visited
- Downloads panel, ad/tracker blocker, force dark, translation, find in page, zoom, dev tools
- Hungarian and English UI

## Install
Download the `.pkg.tar.zst` from the [latest release](https://github.com/Prophet1218/Glass-Browser-Desktop/releases/latest):
```
sudo pacman -U glass-browser-desktop-*.pkg.tar.zst
```

## Build from source
```
sudo pacman -S --needed base-devel cmake qt6-base qt6-declarative qt6-webengine qt6-shadertools kwindowsystem
makepkg -si
```

## Keyboard shortcuts
| Keys | Action |
|---|---|
| Ctrl+T / Ctrl+Shift+N | New tab / new private tab |
| Ctrl+W, Ctrl+Shift+T | Close tab, reopen closed tab |
| Ctrl+L | Focus address bar |
| Ctrl+Tab / Ctrl+1…9 | Switch tabs |
| Ctrl+Shift+A | Tab overview |
| Ctrl+F, Ctrl+D | Find in page, bookmark |
| Ctrl+H, Ctrl+J, Ctrl+, | History, downloads, settings |
| Ctrl + / − / 0 | Zoom |
| F11, F12 | Full screen, developer tools |

Every push to `main` builds the Arch package on GitHub Actions and publishes it as a release.
