# Settings Version Footer — Design Spec

**Date:** 2026-06-15
**Status:** Implemented

## Goal

Show the app version at the bottom-left of the Settings sidebar:
- **Release / prod builds** show the marketing version from the release tag (e.g. `v1.1.2`).
- **Local Debug builds** show `git describe` (e.g. `v1.1.1-8-g1441af7`, `-dirty` when build inputs are uncommitted) for precise build identification.

## Why two sources (the prod-safety reason)

`git describe` is great locally but **unreliable in CI**: the release workflow checks out with `actions/checkout@v4` defaults (shallow, no tags), so `git describe --tags` can't find the tag and would fall back to a bare SHA. Meanwhile the release workflow **already injects the correct version** at archive time:

```
xcodebuild archive -configuration Release \
  MARKETING_VERSION="${GIT_TAG#v}" CURRENT_PROJECT_VERSION="${GITHUB_RUN_NUMBER}" ...
```

So prod's `CFBundleShortVersionString` is the real tag version with no git dependency. The footer reads that in Release and keeps `git describe` only for Debug. The split is gated by `#if DEBUG`.

## Behavior

| Build | Footer |
|-------|--------|
| Release / CI (tag `v1.1.2`) | `v1.1.2` |
| Local Debug, N commits past tag | `v1.1.1-8-g1441af7` |
| Local Debug, build inputs dirty | `v1.1.1-8-g1441af7-dirty` |
| Local Debug, no git available | `unknown` |

### Definition of "dirty"

Uncommitted changes to build inputs `Sources/` and `project.yml` (`git status --porcelain -- Sources project.yml` non-empty). Docs and gitignored artifacts (`.build/`, `dist/`, `*.xcodeproj`) don't count.

## Architecture

`AppVersion` (caseless enum namespace, app target). The view calls `AppVersion.footer()`.

### Release path

`footer()` (`#else`) returns `"v" + CFBundleShortVersionString`. No git, no `Process` — the `git`/runtime helpers live inside `#if DEBUG` and aren't compiled into the shipped binary.

### Debug path

`footer()` (`#if DEBUG`) resolves `git describe` + dirty via:
1. **Info.plist stamp** — `scripts/stamp-git-info.sh` (XcodeGen `postBuildScripts`) writes `GitDescribe`/`GitDirty`, **only when `CONFIGURATION == Debug`** (release builds skip it, keeping the prod Info.plist clean). Used by the sandboxed local `.app`, which can't exec git.
2. **Runtime `git describe`** — for the non-sandboxed dev binary (`swift run`). Anchors on the working directory first (the repo root when launched from it), then `#filePath`.
3. Falls back to `"unknown"`.

### Pure formatters (unit-tested)

- `releaseFooter(marketingVersion:) -> String` → `"v\(marketingVersion)"`
- `devFooter(describe:dirty:) -> String` → `describe` + `-dirty` when dirty

## Testing

- Unit tests (`Tests/WorldCupBarTests/AppVersionTests.swift`): `releaseFooter`, `devFooter` (describe / clean-tag / dirty / unknown), and a `footer()` resolution smoke test.
- Manual: Debug `.app` and dev binary show `git describe`; a Release build with an injected `MARKETING_VERSION` shows `v{version}` and carries no `GitDescribe` key.

## Files

| File | Change |
|------|--------|
| `Sources/WorldCupBar/App/AppVersion.swift` | Hybrid resolver + pure formatters; DEBUG-only git helpers |
| `Sources/WorldCupBar/Settings/SettingsView.swift` | Sidebar `VStack` + `AppVersion.footer()` |
| `scripts/stamp-git-info.sh` | Stamps `GitDescribe`/`GitDirty` (Debug only) |
| `project.yml` | `postBuildScripts` Run Script phase |
| `Tests/WorldCupBarTests/AppVersionTests.swift` | Formatter + smoke tests |

## Non-Goals (YAGNI)

- No build/run number in the release footer — just the marketing version. (Easy to add `(build N)` from `CFBundleVersion` if wanted.)
- No "click to copy", no About window.
