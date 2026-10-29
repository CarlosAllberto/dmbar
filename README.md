<div align="center">

<img src="DMBar/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" alt="DMBar icon" width="128">

# DMBar

**Your Instagram DMs in the macOS menu bar.**

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![No dependencies](https://img.shields.io/badge/dependencies-none-lightgrey)
![License MIT](https://img.shields.io/badge/license-MIT-blue)

[Features](#features) • [Install](#install) • [Usage](#usage) • [How it works](#how-it-works) • [Limitations](#limitations)

English • <a href="README.pt-BR.md">Português</a>

</div>

DMBar is a native menu bar app that shows only your Instagram direct messages. Read and reply without opening a browser and without seeing the feed, stories or reels.

The app loads the official Instagram website in a `WKWebView`. It does not use any private Instagram API and does not automate requests.

<p align="center">
  <img src="docs/screenshots/inbox.png" alt="Conversation list in the DMBar popover" width="32%">
  <img src="docs/screenshots/conversa.png" alt="Open conversation in DMBar" width="32%">
  <img src="docs/screenshots/pedidos.png" alt="Message requests in DMBar" width="32%">
</p>

> [!NOTE]
> DMBar is an independent project. It is not affiliated with Instagram or Meta.

## Features

- **DMs only:** conversation list and chat in a 380x560 popover, with no navigation bar, feed or Notes.
- **Persistent login:** sign in once with username and password or with Facebook. Two-factor authentication works inside the app.
- **Unread badge:** the number of unread conversations appears next to the menu bar icon.
- **Native notifications:** you get a notification when a message arrives while the popover is closed. Click it to open the popover.
- **Global shortcut:** <kbd>⌥</kbd> <kbd>D</kbd> opens and closes DMBar from any app.
- **Launch at login:** option in the icon menu.
- **No Dock icon:** the app lives only in the menu bar.

## Install

### Download the prebuilt app

1. Download `DMBar.zip` from the [latest release](https://github.com/CarlosAllberto/dmbar/releases/latest).
2. Unzip it and move `DMBar.app` to `/Applications`.
3. Open the app.

> [!NOTE]
> The app is not notarized by Apple yet, so macOS asks for confirmation the first time you open it. Go to **System Settings > Privacy & Security** and click **Open Anyway**.

Releases are built by GitHub Actions from this repository for every `v*` tag.

### Build from source

Requirements:

- macOS 13 or later
- Xcode 15 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

The Xcode project is generated from [`project.yml`](project.yml) and is not committed.

```bash
git clone https://github.com/CarlosAllberto/dmbar.git
cd dmbar
xcodegen generate
xcodebuild -project DMBar.xcodeproj -scheme DMBar -configuration Release -derivedDataPath build build
```

The app is created at `build/Build/Products/Release/DMBar.app`. Copy it to `/Applications` and open it.

> [!TIP]
> For development, open `DMBar.xcodeproj` in Xcode and run the `DMBar` scheme. Run `xcodegen generate` again whenever you add or remove files.

> [!NOTE]
> The app is ad-hoc signed (`CODE_SIGN_IDENTITY: "-"`) to run on your own Mac. To distribute it, set your team in `project.yml` and notarize the app.

## Usage

| Action | How |
| --- | --- |
| Open or close your DMs | Click the icon or press <kbd>⌥</kbd> <kbd>D</kbd> |
| Go back to the list | `‹` arrow in the top left corner |
| Reload the page | Right-click the icon, **Recarregar** |
| Launch at login | Right-click the icon, **Abrir ao iniciar o Mac** |
| Sign out of Instagram | Right-click the icon, **Sair da conta…** |
| Quit the app | Right-click the icon, **Sair** |

The first time, sign in inside the popover and allow notifications when macOS asks.

> [!NOTE]
> The app interface is in Portuguese for now. Instagram itself follows your account language.

## How it works

```
DMBar/
├── App/        AppDelegate: icon, popover, menu and badge
├── UI/         Popover
├── Web/        Shared WKWebView, injected CSS and JS
└── Services/   Notifications, global shortcut (Carbon)
```

- **One WebView that stays alive.** `WebViewHost` creates a single `WKWebView`. When the popover closes, the view moves to a hidden window, so the page keeps receiving messages and updating the badge.
- **Injected CSS and JS.** [`Scripts.swift`](DMBar/Web/Scripts.swift) hides everything that is not a DM and fits the layout to the popover. At 380px, the list and the conversation show one at a time.
- **Unread counter.** The script reads the number from the page title, the DM icon and the tabs, and sends the highest value to Swift.
- **Facebook login.** Instagram needs to read the `facebook.com` cookie, so DMBar allows third-party cookies in its own data store. Safari and other apps are not affected.

## Limitations

> [!NOTE]
> The layout depends on Instagram's HTML, which can change at any time. If the feed or the navigation bar shows up again, update the selectors in [`Scripts.swift`](DMBar/Web/Scripts.swift).

- The badge counts unread **conversations**, not messages. It is the same number Instagram shows.
- Notifications say how many conversations are unread, but do not show the sender or the text.
- Allowing third-party cookies uses an internal WebKit interface. If Apple removes it, only Facebook login stops working. Username and password still work.
- The shortcut is fixed to <kbd>⌥</kbd> <kbd>D</kbd>.
- One account at a time.

## Development

Debug builds include tools to adjust the CSS:

- **Web Inspector:** inspect the `WKWebView` from Safari's Develop menu.
- **Snapshot and DOM:** every 3 seconds the app saves `dmbar.png` and `dom.txt` to `~/Library/Containers/com.treendz.dmbar/Data/tmp/`.
- **Copy DOM:** the icon menu gets a **Debug: copiar DOM** item.
- **Start page:** the `DMBAR_URL` variable sets the first page to load.
- **Demo mode:** with `DMBAR_DEMO=1`, names, messages and photos are replaced with fake data and Unsplash portraits. The screenshots in this README were made this way. The photos follow the [Unsplash license](https://unsplash.com/license), not the project's MIT license.

```bash
DMBAR_URL=https://www.instagram.com/direct/requests/ build/Build/Products/Debug/DMBar.app/Contents/MacOS/DMBar
```
