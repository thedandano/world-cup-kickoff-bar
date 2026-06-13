# Contributing to World Cup Bar

Thanks for taking the time to contribute. This is a small side project built during the 2026 World Cup — contributions that keep it fast, native, and focused are very welcome.

## Before You Start

For anything beyond a bug fix or small improvement, open an issue first. It avoids wasted effort if the change doesn't fit the project's direction.

## Setup

```bash
git clone https://github.com/thedandano/world-cup-kickoff-bar.git
cd world-cup-kickoff-bar
swift build
swift test
```

Requires macOS 14.0+ and Xcode 15+ (or the Swift 5.9 toolchain).

## Ground Rules

- **MVVM is strict.** No business logic in Views, no UI imports in Core.
- **Tests are required.** New logic in `WorldCupBarCore` needs a corresponding test in `WorldCupBarCoreTests`.
- **Lint before opening a PR.** Run `swiftlint lint --strict`. CI will fail on violations.
- **Small, focused PRs.** One concern per PR — easier to review and less likely to conflict.

## What's Welcome

- Bug fixes
- Performance improvements (especially anything touching the main thread)
- Additional country flag support
- Localisation
- Accessibility improvements

## What's Out of Scope

- Electron / web tech of any kind
- Adding external dependencies without discussion
- Features that require backend infrastructure or paid APIs

## Submitting a PR

1. Fork the repo and create a branch: `git checkout -b fix/brief-description`
2. Make your changes, write tests, run lint
3. Open a PR against `main` with a clear description of what changed and why

## Code Style

Follow the patterns already in the codebase. The `CLAUDE.md` file documents the conventions — read it before making structural changes.

---

If this project saved you a trip to a browser during a match, consider [buying me a coffee](https://www.buymeacoffee.com/thedandano). Totally optional, always appreciated.
