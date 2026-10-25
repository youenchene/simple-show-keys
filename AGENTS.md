# AGENTS.md

macOS menu bar app (Swift, SwiftPM, AppKit + SwiftUI, `LSUIElement`) that shows keystrokes on
screen. No Xcode project. Humans: see [README.md](README.md).

## Build

```bash
./run.sh          # build, package, sign, relaunch
swift build       # compile only
```

## Layout (`Sources/ShowKeys/`): light ports & adapters

| Dir | Role |
|---|---|
| `Core/` | pure logic, no AppKit: `Keystroke` (labels, `ctrl+x` combos), `Settings` (options, themes, leaders), `KeyFeed` (keystrokes → items on screen, key-after handling) |
| `Adapters/` | macOS side: `KeyMonitor` (NSEvent → `Keystroke`), `Overlay` (click-through panel), `StatusMenu` (menu bar), `SettingsWindow`, `SettingsStore` (UserDefaults) |
| `App/` | entry point and wiring |

Keep AppKit/SwiftUI out of `Core/`.

## Conventions

- Avoid `@State` / `@Observable`: with Command Line Tools only, the macOS 27 SDK makes them macros
  whose plugin is missing. Use `ObservableObject` + `@Published` + `@ObservedObject`/`@StateObject`.
- Commits use gitmoji + conventional type: `✨ feat: …`, `🐛 fix: …`, `🚀 ci: …`.
- Releases are cut by CI from git tags; don't edit the version in `Support/Info.plist`.
- Keystroke capture needs Accessibility permission. `run.sh` signs with a stable self-signed
  identity so the permission survives rebuilds; never commit signing material.
