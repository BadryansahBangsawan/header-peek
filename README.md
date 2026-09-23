<div align="center">

# Header Peek

**Fetch status and response headers for an `http`/`https` URL. The extra title is the last status — or `Header Peek`.**

Menu extra for macOS 14+. Lives on the **right** of the menu bar. No Dock icon.

<br/>

[![Build](https://github.com/BadryansahBangsawan/header-peek/actions/workflows/ci.yml/badge.svg)](https://github.com/BadryansahBangsawan/header-peek/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/header-peek?style=flat-square)](https://github.com/BadryansahBangsawan/header-peek/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/header-peek/releases/latest)

<br/>

![Header Peek panel](docs/panel.png)

| | |
|---|---|
| Product | `HeaderPeek` |
| Bundle ID | `engineer.badry.headerpeek` |
| Status item | SF Symbol `globe` (last HTTP status, or `Header Peek`) |
| Panel | opaque ~360×420 pt |

</div>

---

## What you get

| Piece | Behavior |
|---|---|
| **Fetch** | `http` and `https` only. Each hop tries `HEAD`, then `GET` on `405` / `501` or a request error. |
| **Redirects** | Follows `Location` for at most 10 hops. `URLSession` does not auto-follow. |
| **Headers** | CORS, cache, CSP, HSTS, and server first. Everything else under **Other**. |
| **Copy** | **Copy as curl** → `curl -sS -D - -o /dev/null --max-redirs 10 -L '<url>'`. **Copy headers** → last hop as `Name: value`. |
| **Recents** | Cap 20 at `~/Library/Application Support/Header Peek/recents.json`. |
| **Login** | Open at Login from Settings (`SMAppService`). |

---

## Download

| File | Use |
|---|---|
| **`HeaderPeek.app.zip`** | Unzip, drag **HeaderPeek** onto **Applications** |

**[Releases](https://github.com/BadryansahBangsawan/header-peek/releases/latest)**

---

## Install

### Zip

1. Download `HeaderPeek.app.zip` from [Releases](https://github.com/BadryansahBangsawan/header-peek/releases/latest).
2. Unzip. Drag **HeaderPeek** onto **Applications**.
3. First open (ad-hoc signed):

```bash
xattr -cr /Applications/HeaderPeek.app
open /Applications/HeaderPeek.app
```

Still blocked: System Settings → Privacy & Security → Open Anyway.

### Source

```bash
git clone https://github.com/BadryansahBangsawan/header-peek.git
cd header-peek
bash package-app.sh
ditto dist/HeaderPeek.app /Applications/HeaderPeek.app
xattr -cr /Applications/HeaderPeek.app
open /Applications/HeaderPeek.app
```

Do not run `dist/HeaderPeek.app` while `/Applications/HeaderPeek.app` is running (same bundle ID).

---

## How to open

This is an `LSUIElement` extra. Proof it is running is the **globe** status item on the **right** of the menu bar, not a window from Finder or Launchpad.

1. Click that extra. The panel is opaque ~360×420 pt, not a 10px strip.
2. If the bar is full, look behind the Control Center overflow chevron **«**.
3. Double-clicking in Finder/Launchpad only changes the left-side app name. That is expected. There is no Dock icon.

---

## Usage

1. Click the extra.
2. Enter an `https://` URL and click **Fetch**.
3. Read each hop: method, status, duration, then interesting headers.
4. **Copy as curl** / **Copy headers**. Click a recent to prefill.
5. **Settings** at the bottom: Open at Login, Quit.

`https://example.com` → `HEAD 200`. Menu title becomes `200`.

`ftp://example.com` → red **URL must be http or https.** No request is sent.

---

## Permissions

No TCC prompts. `Info.plist` sets `NSAllowsArbitraryLoads` so `http` hosts are reachable.

---

## Data

| What | Where |
|---|---|
| Recents | `~/Library/Application Support/Header Peek/recents.json` |
| Open at Login | `SMAppService.mainApp` (Settings toggle) |

A missing recents file is an empty list. A file that will not decode is an empty list plus a red banner. The extra does not crash.

---

## Privacy

Fetch uses an ephemeral `URLSession` (no cookies). The URL you type leaves this Mac only as that HTTP request.

---

## Uninstall

Delete `/Applications/HeaderPeek.app`. Then:

```bash
rm -rf "$HOME/Library/Application Support/Header Peek"
```

Turn off **Header Peek** in System Settings → General → Login Items if it remains.

---

## Troubleshooting

| What you see | What to do |
|---|---|
| Finder “opens” nothing / no Dock icon | Click the **globe** extra on the right of the menu bar. |
| Extra missing | Overflow **«**, or `pgrep -x HeaderPeek` then `open /Applications/HeaderPeek.app`. |
| “Damaged” / cannot verify | `xattr -cr /Applications/HeaderPeek.app`. `spctl --assess` is `rejected` even when it runs. |
| **URL must be http or https.** | Use an `http` or `https` URL. |
| **Invalid URL** | Empty field, or a host with no scheme (`example.com`). Prefix `https://`. |
| **Stopped after 10 redirects.** | The URL redirected more than 10 times. |
| ~10px empty strip under the bar | Reinstall from this repo. |

---

## Build from source

```bash
git clone https://github.com/BadryansahBangsawan/header-peek.git
cd header-peek
swift build -c release --product HeaderPeek
bash package-app.sh
open dist/HeaderPeek.app
```

Tag `v*` runs CI: `HeaderPeek.app.zip`. Never commit `dist/`.

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`. `FunTheme.swift` is copied verbatim (no shared package).

---

## FAQ

**Why is there no Dock icon?**  
It is a menu extra. Click the globe item on the **right** of the menu bar.

**Does this need Accessibility?**  
No. It issues HTTP from this Mac.

**Where did the URL list go?**  
`~/Library/Application Support/Header Peek/recents.json` (20 URLs).

**How do I stop it opening at login?**  
Settings in the panel, or System Settings → General → Login Items → **Header Peek**.

---

<div align="center">

[MIT](LICENSE)

</div>
