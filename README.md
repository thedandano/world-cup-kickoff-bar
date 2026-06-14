# World Cup Bar

<div align="center">

  **A native macOS menu bar app for the 2026 FIFA World Cup**

  ![macOS](https://img.shields.io/badge/macOS-14.0+-black?style=flat-square&logo=apple)
  ![Swift](https://img.shields.io/badge/Swift-6.0+-orange?style=flat-square&logo=swift)
  ![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-blue?style=flat-square&logo=swift)
  ![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
  ![Platform](https://img.shields.io/badge/platform-MacOS-purple?style=flat-square)



  <a href="https://www.buymeacoffee.com/CagXd3ZFyZ"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=CagXd3ZFyZ&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" /></a>

  Live scores. Upcoming fixtures. Kickoff alerts.  
  All from your menu bar. No browser required.

</div>

---

## Overview

World Cup Bar is a lightweight, native macOS menu bar application that keeps you on top of every 2026 FIFA World Cup match without disrupting your workflow. A single click shows live scores, upcoming fixtures filtered to teams you follow, and a countdown to the next kickoff. Notifications fire before your team takes the pitch.

Built with Swift 5.9, SwiftUI, and the `@Observable` macro. No Electron. No browser. Just native macOS.

---

## Features

- **Live score in the menu bar** — team codes or flag emoji, your choice
- **Follow your teams** — followed matches get priority in the display and dropdown
- **Upcoming fixtures** — next 5 matches with venue and local kickoff time (Today / Tomorrow / weekday)
- **Kickoff notifications** — configurable lead time: Off / 5 / 15 / 30 / 60 minutes before kickoff
- **Smart polling** — 30 s during live matches, 5 min otherwise; change-detection skips redundant UI updates
- **Offline resilience** — last snapshot cached to disk, shown immediately on next launch
- **Privacy-first analytics** — powered by TelemetryDeck, fully opt-out in Settings

---

## Requirements

- macOS 14.0 (Sonoma) or later
- Network access — match data is fetched from `worldcup26.ir` (no auth required)

---

## Build from Source

```bash
git clone https://github.com/YOUR_USERNAME/world-cup-kickoff-bar.git
cd world-cup-kickoff-bar
swift build -c release
```

### Run Tests

```bash
swift test
```

### Lint

```bash
swiftlint lint --strict
```

---

## Architecture

Strict MVVM with a Core / UI module split. Zero UI code in Core; zero business logic in Views.

```
WorldCupBarCore   — pure Swift, no UI, no external deps
                    WorldCupMatch, Country, WorldCupSnapshot
                    WorldCup26APIClient, WorldCup26Mapper
                    WorldCupRepository (retry + cache + change-detection)
                    MatchFormatter, MatchSelectionService

WorldCupBar       — SwiftUI app (macOS menu bar + settings window)
                    WorldCupBarViewModel (@Observable, @MainActor)
                    MenuBarDropdownView, SettingsView
                    NotificationScheduler, WorldCupMonitoringService
```

Key patterns:

| Pattern | Why |
|---------|-----|
| `@Observable` macro | Replaces `ObservableObject`/`@Published`; SwiftUI tracks access automatically |
| Protocol-backed services | `WorldCupDataProviding`, `NotificationScheduling`, `WorldCupAnalyticsTracking` — all swappable in tests |
| Change-detection in repository | `matchesContentEqual` skips the store write and ViewModel update when nothing changed |
| `VisualEffectBackground` | `NSVisualEffectView` with `.behindWindow` blending for the menu bar popover |
| `SettingsWindowBackground` | Installs vibrancy at the `NSWindow.contentView` level + clears `NSSplitView` pane backgrounds for full settings-window translucency |

---

## Data

Match data is sourced from [worldcup26.ir](https://worldcup26.ir). No authentication required for read endpoints. The mapper skips TBD knockout bracket slots (`team_id: 0`) so placeholder games never appear in the UI.

---

## Privacy

No personal data is collected. Anonymous product analytics are powered by [TelemetryDeck](https://telemetrydeck.com) — only app version and basic usage events are sent. Analytics can be disabled entirely in **Settings → Analytics**. All other data (followed teams, preferences, cached match data) is stored locally on your device.

---

## Contributing

Pull requests are welcome. For significant changes, open an issue first to discuss the approach.

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Follow the patterns in `CLAUDE.md` (MVVM, no business logic in views, tests required)
4. Run `swiftlint lint --strict` and `swift test` before opening a PR

---

## License

MIT License — see [LICENSE](LICENSE) for the full text.

> **No warranty is provided.** This software is offered as-is. The authors are not responsible for any issues arising from its use.

---

<div align="center">
  <sub>Built for the 2026 FIFA World Cup · Data from worldcup26.ir · Unaffiliated with FIFA</sub>
</div>
