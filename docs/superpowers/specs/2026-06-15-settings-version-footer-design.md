# Settings Version Footer — Design Spec

**Date:** 2026-06-15
**Status:** Implemented

## Goal

Show the app version at the bottom-left of the Settings sidebar:
- **Local Debug builds** show `git describe` (e.g. `v1.1.1-9-g6b3d93c`, `-dirty` when build inputs are uncommitted) for precise build identity.
- **Release / prod builds** show the marketing version from the release tag (e.g. `v1.1.2`).

## Approach (after `llm-bench`)

The release-vs-dev decision lives in the **build script**, keyed on `CONFIGURATION` — not in Swift via `#if DEBUG`, and never via runtime git. This keeps the Swift side a pure formatter, keeps prod independent of git history (CI checkouts are shallow), and avoids the SwiftPM-vs-Xcode and sandbox/cwd pitfalls of a runtime approach.

- **Debug build** → `scripts/stamp-git-info.sh` (Xcode `postBuildScripts`) writes a custom `DisplayVersion` key = `git describe` (leading `v` stripped, `-dirty` appended for uncommitted `Sources/`/`project.yml`).
- **Release build** → the script exits early (CONFIGURATION ≠ Debug), so no `DisplayVersion`; the footer falls back to `CFBundleShortVersionString`, which CI sets from the tag (`MARKETING_VERSION="${GIT_TAG#v}"`).

The app reads `DisplayVersion`, then `CFBundleShortVersionString`, then a `dev build` placeholder, and prepends `v`.

## Behavior

| Build | Footer | Source |
|-------|--------|--------|
| Xcode Debug `.app` (⌘R) | `v1.1.1-9-g6b3d93c` (`-dirty` if uncommitted) | `DisplayVersion` (`git describe`) |
| CI Release / archive | `v1.1.2` | `CFBundleShortVersionString` (tag-injected) |
| SwiftPM dev binary (`swift run`) | `dev build` | none (no processed Info.plist) |

**Run model:** UAT the version via the Xcode `.app` (⌘R), like `llm-bench` (Xcode-only). The SwiftPM dev binary is for `swift test`; it has no Info.plist, so it shows the placeholder.

### Definition of "dirty"

Uncommitted changes to build inputs `Sources/` and `project.yml` (`git status --porcelain -- Sources project.yml` non-empty). Docs and gitignored artifacts don't count.

## Architecture

- `Sources/WorldCupBar/App/AppVersion.swift` — `enum AppVersion` with:
  - `footer(bundle:) -> String` — reads `DisplayVersion` / `CFBundleShortVersionString`.
  - `footer(displayVersion:marketingVersion:) -> String` — **pure**, unit-tested: first non-empty, non-`0.0.0` value wins, prefixed `v`; else `dev build`.
- `scripts/stamp-git-info.sh` — Debug-only; sanitizes the describe value to the git-describe charset before the PlistBuddy command (defense-in-depth).
- `project.yml` — `postBuildScripts` runs the script on the `WorldCupBar` target.
- `Sources/WorldCupBar/Settings/SettingsView.swift` — sidebar `VStack` + `Text(AppVersion.footer())`, styled via `WorldCupBarTheme` tokens.

## Testing

Unit tests (`Tests/WorldCupBarTests/AppVersionTests.swift`) for the pure formatter: stamped-describe wins, dirty marker kept, marketing fallback, `dev build` placeholder, empty/`0.0.0` ignored. Manual: Debug `.app` shows `git describe`; a Release build with an injected `MARKETING_VERSION` shows `v{version}` and carries no `DisplayVersion`.

## Non-Goals (YAGNI)

- No runtime `git` in the app; no `#if DEBUG` gating; no SwiftPM dev-binary version support.
- No build/run number in the footer.
- (Optional follow-up) Have release-please commit the `MARKETING_VERSION` bump into `project.yml` (extra-files), like `llm-bench`, so the non-injected default isn't stale at `1.0.0`. Not required — CI injects the correct version at archive time.
