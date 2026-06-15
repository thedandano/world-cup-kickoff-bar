# Settings Version Footer — Design Spec

**Date:** 2026-06-15
**Status:** Implemented

## Goal

Show the app version at the bottom-left of the Settings sidebar, derived from `git describe --tags` (e.g. `v1.1.1-5-g5450215`) so it always reflects the real git state rather than a hardcoded build setting. A `-dirty` marker flags uncommitted build-input changes. At a release tag the string collapses to just the tag (e.g. `v1.1.1`).

> **Revision note:** an earlier draft showed `v{MARKETING_VERSION} (build {CFBundleVersion})` gated by `#if DEBUG`. That was changed because `MARKETING_VERSION` is a hardcoded build setting that had gone stale (`1.0.0` while the latest tag was `v1.1.1`), and running the SwiftPM dev binary showed the empty-bundle fallback (`0.0.0`). `git describe` fixes both: it derives the version from tags and self-cleans at release commits.

## Behavior

The footer is muted caption text pinned at the bottom of the Settings sidebar, visible regardless of which panel is selected.

| Situation | Footer text |
|-----------|-------------|
| Local build, N commits past the tag | `v1.1.1-5-g5450215` |
| Exactly at a release tag (CI release) | `v1.1.1` |
| Build inputs dirty | `v1.1.1-5-g5450215-dirty` |
| No git available (e.g. source tarball) | `unknown` |

Because `git describe` already returns just `v1.1.1` at a tagged commit and the `-N-gSHA` detail only between tags, no `#if DEBUG` format gate is needed — release builds are clean automatically.

### Definition of "dirty"

"Dirty" means **uncommitted changes that can influence the built app** — staged, unstaged, or untracked changes under the build inputs `Sources/` and `project.yml`. Docs (`README.md`, `docs/`, `CLAUDE.md`) and gitignored artifacts (`.build/`, `dist/`, `*.xcodeproj`) don't count. Implementation: `git status --porcelain -- Sources project.yml` non-empty.

## Architecture

### 1. Build-time git injection

The sandboxed app can't run `git` at runtime, so the value is injected at build time into the **built product's** Info.plist (not the source plist — keeps the source tree clean so it doesn't self-dirty).

A Run Script build phase on the `WorldCupBar` target (`scripts/stamp-git-info.sh`, wired via XcodeGen `postBuildScripts`) writes two keys:
- `GitDescribe` (String) = `git describe --tags --always --abbrev=7`, or `unknown` with no git.
- `GitDirty` (Bool) = the scoped dirty check above.

It runs after Info.plist processing and before code signing, guards on a missing plist, and never fails the build.

### 2. `AppVersion` (app target)

```swift
struct AppVersion {
    let describe: String   // "v1.1.1-5-g5450215", "v1.1.1", or "unknown"
    let dirty: Bool
    var footer: String { dirty ? "\(describe)-dirty" : describe }
    static func current(bundle: Bundle = .main) -> AppVersion
}
```

`current()` resolution order:
1. **Bundle stamp** — `GitDescribe`/`GitDirty` from Info.plist. Always present in the real (Xcode-built) app, Debug or Release.
2. **DEBUG-only runtime fallback** — when the stamp is absent (e.g. the SwiftPM dev binary run via `swift run`, which has no processed Info.plist), read `git describe` at runtime, locating the checkout from `#filePath`. Only reachable by the non-sandboxed dev binary; the sandboxed app can't exec git, so it never needs this path. Compiled out of Release entirely (`#if DEBUG`).
3. Otherwise `unknown`.

### 3. Footer view

`SettingsView` wraps the sidebar `List` in a `VStack(spacing: 0)` with a `versionFooter` (`Divider` + `Text(AppVersion.current().footer)`), styled via `WorldCupBarTheme` tokens (`WCBFont.caption`, `WCBColor.secondaryLabel`, `WCBSpacing.medium/small`).

## Data Flow

```
build phase (git describe) ─→ product Info.plist {GitDescribe, GitDirty}
                                     └─→ AppVersion.current() ─→ .footer ─→ sidebar Text
dev binary (no stamp) ── #if DEBUG runtime `git describe` ──────┘
```

## Testing

- Unit tests (`Tests/WorldCupBarTests/AppVersionTests.swift`) for `AppVersion.footer`: between-tags, clean-tag, dirty, unknown.
- A resolution smoke test: `AppVersion.current().describe` is non-empty (exercises the bundle→runtime→unknown path without crashing).
- Manual: build & run; confirm the sidebar footer. The Xcode `.app` shows the stamped value; the dev binary shows the runtime value.

## Files

| File | Change |
|------|--------|
| `scripts/stamp-git-info.sh` | Stamps `GitDescribe`/`GitDirty` into the product Info.plist |
| `project.yml` | `postBuildScripts` Run Script phase on `WorldCupBar` |
| `Sources/WorldCupBar/App/AppVersion.swift` | `AppVersion` reader + footer + DEBUG runtime fallback |
| `Sources/WorldCupBar/Settings/SettingsView.swift` | Sidebar `VStack` + version footer |
| `Tests/WorldCupBarTests/AppVersionTests.swift` | Footer + resolution tests |

## Non-Goals (YAGNI)

- No "click to copy", no About window.
- No separate `(build N)` — `git describe`'s commit-count is more meaningful than `CFBundleVersion` locally.
