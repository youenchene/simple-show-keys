# Simple Show Keys

A tiny macOS menu bar app that shows your keystrokes on screen, for demos and screen recordings.

- **Shortcuts**: `⌘K`, `⌃C`, `⇧⇥`
- **Special keys**: `↩ ⎋ ⌫ ← →`
- **Typed text**: grouped into one bubble (`hello world`)
- **Key after**: after a leader shortcut, the next key is shown with it: `⌃X › N`.
  `ctrl+x` (opencode) is on by default; `ctrl+b` (tmux), `ctrl+a`, `ctrl+k`, `cmd+k`, `ctrl+w` are
  one click away, and you can add your own.

Lives only in the menu bar (no Dock icon). The menu has quick toggles and **Settings…**: what to
show, size (small → huge), colors (Midnight, OpenCode, Light, Dracula, Nord, Solarized, Sunset,
Matrix, High contrast), position, display time, and leaders.

## Install

Download the `.dmg` from [Releases](../../releases), drag the app to Applications, launch it, and
allow it under **System Settings → Privacy & Security → Accessibility** (needed to see keystrokes).

## Develop

```bash
./run.sh              # build → package .build/SimpleShowKeys.app → sign → launch
swift build           # compile only
./make_icon           # re-render Support/AppIcon.icns from Scripts/render_icon.swift
```

Requires macOS 14+ and Swift 5.10+ (Command Line Tools are enough).

## Release

CI (`.github/workflows/release.yml`) builds a signed, notarized arm64 `.dmg` and publishes a
GitHub Release on every merge to `main` (patch bump; minor/major via manual dispatch). Secrets:
`APPLE_CERTIFICATE`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_SIGNING_IDENTITY`, `APPLE_ID`,
`APPLE_TEAM_ID`, `APPLE_APP_PASSWORD`.
