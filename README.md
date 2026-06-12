# World Cup Bar

A lightweight macOS menu bar app for the 2026 FIFA World Cup. See live scores, upcoming fixtures, and get notified before your team kicks off — without opening a browser.

## Features

- Live score in the menu bar (codes or flags)
- Upcoming match list with venue and local kickoff time
- Follow your teams — followed matches get top priority
- Pre-match notifications (configurable: Off / 5 / 15 / 30 / 60 min)
- Auto-updates via Sparkle
- Privacy-first analytics (TelemetryDeck, opt-out in Settings)

## Requirements

- macOS 13.0+
- Network access (fetches from `worldcup26.ir`)

## Build

```bash
git clone https://github.com/michilotl/world-cup-kickoff-bar.git
cd world-cup-kickoff-bar
swift build -c release
```

## Test

```bash
swift test
```

## Lint

```bash
swiftlint lint --strict
```

## Release

Releases are built and signed by GitHub Actions (`cd.yml`). The workflow:

1. Builds a release binary via `swift build -c release`
2. Packages it into a signed `.app` bundle
3. Notarizes with Apple
4. Creates a zip for Sparkle distribution
5. Generates/updates the Sparkle appcast
6. Publishes as a GitHub Release

See `.github/workflows/cd.yml`.

## Architecture

MVVM with a strict Core / UI module split.

```
WorldCupBarCore   — pure Swift, no UI, no external deps
WorldCupBar       — SwiftUI app (menu bar + settings window)
```

See `CLAUDE.md` for full developer guide.

## Data

Match data is sourced from [worldcup26.ir](https://worldcup26.ir). No authentication required for read endpoints. Polls every 30 s during live matches, every 5 min otherwise.

## Privacy

No personal data is collected. Analytics are powered by [TelemetryDeck](https://telemetrydeck.com) and can be disabled in Settings → Analytics. Data is stored locally on your device only.

## License

© 2026 Michilotl Studios. All rights reserved.  
This is a paid season-pass app for the 2026 FIFA World Cup.
