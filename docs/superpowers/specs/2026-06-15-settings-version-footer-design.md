# Settings Version Footer — Design Spec

**Date:** 2026-06-15
**Status:** Draft for review

## Goal

Show the app version at the bottom-left of the Settings sidebar. Local (Debug) builds additionally show the git short SHA and a `-dirty` marker so the developer can identify exactly which local build is running. Release/CI builds show a clean version with no git detail.

## Behavior

The footer is muted caption text pinned at the bottom of the Settings sidebar (below the panel list), visible regardless of which panel is selected.

| Build | Footer text |
|-------|-------------|
| Release / CI | `v1.1.1 (build 42)` |
| Local Debug, clean | `v1.1.1 (build 1) · 90ed77e` |
| Local Debug, dirty | `v1.1.1 (build 1) · 90ed77e-dirty` |
| Local Debug, no `.git` | `v1.1.1 (build 1) · unknown` |

- `v{X.Y.Z}` ← `CFBundleShortVersionString` (existing `MARKETING_VERSION`).
- `(build {N})` ← `CFBundleVersion` (existing `CURRENT_PROJECT_VERSION`).
- The ` · {sha}[-dirty]` suffix is rendered **only under `#if DEBUG`**, so Release builds never surface git detail even though the keys are present in the bundle.

### Definition of "dirty"

"Dirty" means **uncommitted changes that can influence the built app** — not merely tracked modifications, and not stray non-build files.

- **Counts:** any staged, unstaged, or untracked change under the app's build inputs — `Sources/` and `project.yml`. This includes a brand-new untracked `.swift` file (it would be compiled in).
- **Does not count:** changes to docs (`README.md`, `docs/`, `CLAUDE.md`, `AGENTS.md`), and gitignored build artifacts (`.build/`, `dist/`, `*.xcodeproj`) — these are excluded automatically because git status ignores `.gitignore`d paths and we scope the check to build-input paths.
- **Implementation:** `dirty = [ -n "$(git -C "$SRCROOT" status --porcelain -- Sources project.yml)" ]`.

## Architecture

Three small units, each independently understandable and the logic-bearing one independently testable.

### 1. Build-time git injection (the only non-trivial piece)

The app is sandboxed and cannot run `git` at runtime, so git facts are injected at build time into the **built product's** `Info.plist` (not the source plist — see "Why the product plist" below).

A **Run Script build phase** on the `WorldCupBar` target (added via XcodeGen) does:

```sh
set -euo pipefail
PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
SHA="$(git -C "${SRCROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
if [ -n "$(git -C "${SRCROOT}" status --porcelain -- Sources project.yml 2>/dev/null)" ]; then
  DIRTY=true
else
  DIRTY=false
fi
/usr/libexec/PlistBuddy -c "Add :GitSHA string ${SHA}" "${PLIST}" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :GitSHA ${SHA}" "${PLIST}"
/usr/libexec/PlistBuddy -c "Add :GitDirty bool ${DIRTY}" "${PLIST}" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :GitDirty ${DIRTY}" "${PLIST}"
```

Writes two keys: `GitSHA` (String) and `GitDirty` (Bool).

**Graceful degradation:** if `.git` is absent (e.g., a source tarball) the `git` calls fail softly → `SHA=unknown`, `DIRTY=false`. The script must never fail the build on missing git. (The `set -e` above is scoped so the `|| echo unknown` / `2>/dev/null` guards absorb git failures.)

**Phase ordering (correctness-critical):**
- Must run **after** "Process Info.plist" (so `${TARGET_BUILD_DIR}/${INFOPLIST_PATH}` exists) and **before code signing** (Xcode signs after all build phases, so any Run Script phase qualifies — but modifying the plist *after* signing would invalidate the signature, so it must be a build phase, never a post-build/external step). XcodeGen `postCompileScripts` is the intended slot; the implementation must **verify by building** that the processed plist exists when the script runs, and adjust ordering if not.

**Why the product plist (not a generated Swift file):** writing git info into a tracked source file (or a committed `BuildGitInfo.swift`) would modify the working tree on every build and make the tree perpetually "dirty," defeating the dirty signal. Writing to the build-artifact plist leaves `Sources/` untouched, so the dirty check stays accurate and the source tree stays clean.

### 2. Version reader — `AppVersion` (app target)

A tiny value type that reads the four facts from `Bundle.main`, with safe fallbacks (the bundle keys are always present in practice, but nil-coalesce defensively):

```swift
struct AppVersion {
    let version: String   // CFBundleShortVersionString, default "0.0.0"
    let build: String     // CFBundleVersion, default "0"
    let sha: String       // GitSHA, default "unknown"
    let dirty: Bool        // GitDirty, default false

    static func fromBundle(_ bundle: Bundle = .main) -> AppVersion { … }
}
```

### 3. Footer formatter (the tested seam) + view

A **pure** function holds all composition logic, so it is unit-testable without a bundle or a view:

```swift
func footerText(version: String, build: String, sha: String, dirty: Bool, isDebug: Bool) -> String {
    let base = "v\(version) (build \(build))"
    guard isDebug else { return base }
    return "\(base) · \(sha)\(dirty ? "-dirty" : "")"
}
```

`SettingsView`: wrap the sidebar `List` in a `VStack(spacing: 0)` so the list takes available height and a footer sits at the bottom:

```
VStack(spacing: 0) {
    List(...) { ... }
    Divider()
    Text(footer)            // muted caption, leading-aligned, full-width
}
```

The footer text/divider styling routes through **`WorldCupBarTheme` tokens** (color, spacing, font) — no hardcoded literals. If a needed token is missing (e.g., a caption font size or a "tertiary/secondary label" color), add it to the theme rather than inlining a literal.

`isDebug` is supplied at the call site via `#if DEBUG` so the formatter stays pure and both branches are testable.

## Data Flow

```
build phase (git)
  └─→ product Info.plist {GitSHA, GitDirty}
        └─→ AppVersion.fromBundle()  ── version, build, sha, dirty
              └─→ footerText(..., isDebug:)  ── String
                    └─→ SettingsView sidebar footer (Text)
```

## Testing

- **Unit tests** (`Tests/WorldCupBarTests/`, `@testable import WorldCupBar`) for `footerText(...)`:
  - Release (`isDebug: false`) → `v1.1.1 (build 42)` (no suffix even if dirty/sha set).
  - Debug clean → `v1.1.1 (build 1) · 90ed77e`.
  - Debug dirty → `v1.1.1 (build 1) · 90ed77e-dirty`.
  - Debug, `sha: "unknown"`, not dirty → `v1.1.1 (build 1) · unknown`.
- **Manual verification:** build & open Settings → confirm the footer shows version + build + SHA + dirty for a local Debug build; a `-configuration Release` build shows the clean form. (The build script and the SwiftUI layout are verified by eye, not unit tests.)

## Files

| File | Change |
|------|--------|
| `project.yml` | Add a `postCompileScripts` Run Script phase to the `WorldCupBar` target |
| `Sources/WorldCupBar/App/AppVersion.swift` | **New** — `AppVersion` reader + `footerText(...)` formatter |
| `Sources/WorldCupBar/Settings/SettingsView.swift` | Wrap sidebar `List` in a `VStack` + version footer |
| `Sources/WorldCupBar/DesignSystem/WorldCupBarTheme.swift` | Add a caption-font / secondary-color token only if one is missing |
| `Tests/WorldCupBarTests/AppVersionTests.swift` | **New** — `footerText(...)` unit tests |

## Non-Goals (YAGNI)

- No "click to copy version", no About window — just the footer.
- No SHA/dirty in Release builds.
- `GitDirty` is a single boolean; we don't enumerate *what* is dirty.

## Open Questions

None — placement (sidebar bottom-left), format (version + build + SHA + dirty), and the dirty definition (uncommitted build-input changes) are all decided.
