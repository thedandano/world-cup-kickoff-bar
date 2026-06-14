# World Cup Bar — Claude Instructions

## Project Overview

A macOS menu bar app (SwiftUI, Xcode project via XcodeGen, macOS 14+) that shows live World Cup 2026 match scores and upcoming fixtures. Menu bar-only (`LSUIElement = YES`). Distributed as a paid one-time purchase (App Store or direct download).

**Data source:** `worldcup26.ir` — no auth required for read endpoints.  
**Bundle ID:** `com.michilotl.WorldCupBar`  
**Minimum OS:** macOS 13.0

---

## Architecture

### MVVM — strict enforcement

- **Model layer** (`WorldCupBarCore` target): `WorldCupMatch`, `Country`, `WorldCupSnapshot`, repository, mapper, formatter, selection service. Zero UI imports.  
- **ViewModel** (`WorldCupBarViewModel`): `@MainActor @Observable` (Observation macro — `import Observation`, never SwiftUI/AppKit/Combine). Owns all business logic, UserDefaults persistence, `NotificationScheduler` coordination.  
- **View layer** (`WorldCupBar` target): `MenuBarDropdownView`, `SettingsView`, `WorldCupBarApp`. Binds to ViewModel only. Local `@State` is fine for display-only state (e.g., search text).  

Do not put business logic in Views. Do not put UI imports in Core.

### Module split & folder layout

**Hybrid layout** — *feature-up, layer-down*: role-based folders in Core (one domain → group by technical role), feature-based folders in the app (many surfaces → group by feature).

```
WorldCupBarCore   — pure Swift, no UI, no external deps
  Models/         WorldCupMatch, Country, MatchScore, MatchStatus, WorldCupSnapshot,
                  MatchDisplayState, DisplayMode, VSMarkStyle
  DataSource/     WorldCupDataSource (port), WorldCup26DataSource (adapter), WorldCup26Mapper
  Repository/     WorldCupRepository, WorldCupSnapshotStore, RetryPolicy, MatchDataProvider (deprecated alias)
  Services/       MatchSelectionService, MatchFormatter, WorldCupTelemetry

WorldCupBar       — SwiftUI app, depends on Core + TelemetryDeck + Sparkle
  App/            WorldCupBarApp (@main), AppDelegate, WorldCupBarViewModel
  MenuBar/        MenuBarDropdownView, MatchRow, VSMark
  Settings/       SettingsView
  Notifications/  NotificationScheduler
  Analytics/      WorldCupMonitoring (WorldCupAnalyticsTracking + TelemetryDeck adapter)
  Updates/        UpdaterViewModel
  DesignSystem/   WorldCupBarTheme, VisualEffectView
```

---

## Development Commands

The app is an Xcode project generated from `project.yml` (XcodeGen). The `.xcodeproj` is gitignored — regenerate after cloning or changing `project.yml`/file layout.

```bash
# (Re)generate the Xcode project
xcodegen generate

# Build the app (or open WorldCupBar.xcodeproj and ⌘R)
xcodebuild -scheme WorldCupBar -configuration Debug build

# Test — full suite via Xcode, or fast Core-only via SwiftPM
xcodebuild -scheme WorldCupBar -destination 'platform=macOS' test
swift test

# Lint
swiftlint lint --strict
```

> The Xcode project is the source of truth for **building and shipping the app**. `Package.swift` is retained for fast `swift test` of pure-Swift logic; keep deps in sync between `project.yml` and `Package.swift`.

---

## Key Files

| File | Purpose |
|------|---------|
| `Sources/WorldCupBarCore/DataSource/WorldCup26DataSource.swift` | HTTP calls to worldcup26.ir |
| `Sources/WorldCupBarCore/DataSource/WorldCup26Mapper.swift` | Maps API DTOs → domain model; skips TBD knockout games |
| `Sources/WorldCupBarCore/Repository/WorldCupRepository.swift` | Retry + cache + change-detection |
| `Sources/WorldCupBarCore/Services/MatchFormatter.swift` | All string formatting for match display |
| `Sources/WorldCupBar/App/WorldCupBarViewModel.swift` | Observable state, polling, notifications |
| `Sources/WorldCupBar/Notifications/NotificationScheduler.swift` | UNUserNotificationCenter scheduling |
| `Sources/WorldCupBar/MenuBar/MenuBarDropdownView.swift` | Menu bar popover UI |
| `Sources/WorldCupBar/Settings/SettingsView.swift` | Settings window |

---

## Testing

- Framework: Swift Testing (`@Test`, `#expect`)  
- Run: `swift test`  
- Tests live in `Tests/WorldCupBarCoreTests/` (pure logic) and `Tests/WorldCupBarTests/` (ViewModel)  
- Never mock `UNUserNotificationCenter` directly — inject via `NotificationScheduling` protocol  
- Never use `UserDefaults.standard` in tests — inject or isolate  

---

## Change-Detection Polling

`WorldCupRepository.refreshSnapshot` compares the new snapshot against the cached one via `matchesContentEqual`. If scores and statuses are identical, it returns the cached snapshot unchanged — skipping the store write and avoiding unnecessary ViewModel/UI updates.

Polling intervals:
- Live match active: 30 s  
- All other states: 5 min  

---

## Notifications

`NotificationScheduler` schedules `UNCalendarNotificationTrigger` for every upcoming match of a followed country. Notification identifier = `"kickoff-\(match.id)"` — rescheduling is idempotent. Minutes-before is configurable (Off / 5 / 15 / 30 / 60 min); default 15.

---

## Sparkle Auto-Update

Add `SUFeedURL` and `SUPublicEDKey` to `Info.plist` before distributing outside the App Store. Generate keys with `./generate_keys` from the Sparkle binary tools. Store the private key in the CI environment only (never in the repo).

---

## Linting

SwiftLint config: `.swiftlint.yml`. Run before committing. CI will fail on lint errors.

---

## Commits

Frequent, atomic commits. Commit message format: `type(scope): description` (e.g., `feat(notifications): add configurable kickoff alerts`).
