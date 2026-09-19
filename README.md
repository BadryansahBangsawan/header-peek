# Header Peek

Inspect HTTP(S) response headers hop by hop, without following redirects automatically.

Menu extra for macOS 14+. It lives on the **right** of the menu bar and does not show a Dock icon.

| | |
|---|---|
| Product | `HeaderPeek` |
| Bundle ID | `engineer.badry.headerpeek` |
| Status item | SF Symbol `globe` |
| Panel | opaque ~360×420 pt |

## Features

- Fetch `http` / `https` only. Other schemes show **URL must be http or https.**
- Each hop tries `HEAD`, then `GET` on URL error / `405` / `501`.
- Stops after 10 redirects. Location is followed from the hop, not by URLSession auto-redirect.
- Interesting headers (CORS, cache, CSP, HSTS, server, …) listed first; the rest under **Other**.
- **Copy as curl** and **Copy headers**.
- Recents (cap 20). Menu title is the last status code (`200`) or `Header Peek`.

## Requirements

- macOS 14 Sonoma or later
- Swift 5.9 or later only if you build from source
- Network for Fetch

## Install

Build from source:

```bash
git clone https://github.com/BadryansahBangsawan/header-peek.git
cd header-peek
bash package-app.sh
ditto dist/HeaderPeek.app /Applications/HeaderPeek.app
xattr -cr /Applications/HeaderPeek.app
open /Applications/HeaderPeek.app
```

Ad-hoc signed (`codesign -s -`). If Gatekeeper blocks it or says it is damaged, run the `xattr` line above. If still blocked: System Settings → Privacy & Security → Open Anyway.

Do not run `dist/` next to a copy in `/Applications` (same bundle ID).

Enable **Open at Login** from Settings if you want it after reboot.

## How to open

This is an `LSUIElement` extra. Proof it is running is the **globe** status item on the **right** of the menu bar.

1. Click that extra. The panel is opaque (~360×420), not a 10px strip.
2. If the bar is full, look behind the Control Center overflow chevron **«**.
3. Double-clicking in Finder/Launchpad does not open a document window. That is expected. There is no Dock icon.

## Usage

- Enter an `https://` URL → **Fetch**.
- Hop cards show method, status, duration, then interesting headers.
- **Copy as curl** / **Copy headers**. Tap a recent to prefill.
- **Settings** at the bottom: Open at Login, Quit.

## Permissions

Network only. No Accessibility or Screen Recording.

## Data

Recents: `~/Library/Application Support/Header Peek/recents.json`. Missing file is empty. Decode failure is empty plus a red banner.

## Privacy

Fetch uses an ephemeral `URLSession` (no cookies). URLs you type stay on this Mac except the HTTP request itself.

## Uninstall

Delete `/Applications/HeaderPeek.app`. Turn off Open at Login in Settings first if you enabled it.

```bash
rm -rf "$HOME/Library/Application Support/Header Peek"
```

## Troubleshooting

| What you see | What to do |
|---|---|
| No Dock icon | Click the **globe** extra on the right of the menu bar. |
| Extra missing | Overflow **«**, or `open /Applications/HeaderPeek.app`. |
| “Damaged” | `xattr -cr /Applications/HeaderPeek.app` |
| **URL must be http or https.** | Scheme is not `http`/`https`. |
| **Stopped after 10 redirects.** | The URL redirected more than 10 times. |
| Tiny capsule / only Settings | Reinstall from this repo (panel min height 420). |

## Development

```bash
swift build
swift build -c release --product HeaderPeek
```

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`. Never commit `dist/`. FunTheme.swift is copied verbatim (no shared package).

## License

[MIT](LICENSE)
