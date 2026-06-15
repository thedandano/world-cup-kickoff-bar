# Settings Version Footer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show the app version at the bottom-left of the Settings sidebar; local Debug builds additionally show the git short SHA and a `-dirty` marker so the developer can tell which local build is running.

**Architecture:** A build-time Run Script phase stamps `GitSHA` + `GitDirty` into the built product's `Info.plist`. A pure `AppVersion.footerText(...)` formatter (unit-tested) composes the string; the SwiftUI sidebar renders it, gating the git detail behind `#if DEBUG` so Release builds stay clean.

**Tech Stack:** Swift 6, SwiftUI, XcodeGen (`project.yml`), Swift Testing (`@Test`/`#expect`), PlistBuddy. Reference spec: `docs/superpowers/specs/2026-06-15-settings-version-footer-design.md`.

---

## Context for the implementer

- Work in this worktree (branch `worktree-settings-version-footer`, off clean `main`): `/Users/dandano/workplace/world-cup-kickoff-bar/.claude/worktrees/settings-version-footer`. `cd` there for every command.
- Version + build already flow from build settings into `Info.plist`: `CFBundleShortVersionString` = `MARKETING_VERSION` (1.0.0 locally), `CFBundleVersion` = `CURRENT_PROJECT_VERSION` (1 locally). Do **not** change that wiring.
- `swift test` compiles the `WorldCupBar` executable target (incl. `SettingsView`) and both test bundles — it is the fast safety net. The git-stamp build phase is **Xcode-only** (it does not run under `swift build`), so `AppVersion.fromBundle()` returns `sha: "unknown"` under SwiftPM — that's expected; the formatter tests don't depend on the bundle.
- Theme tokens to use (already exist — no theme file change): `WCBColor.secondaryLabel`, `WCBFont.caption`, `WCBSpacing.medium`, `WCBSpacing.small`. Do not hardcode color/font/spacing literals.
- The `·` separator is U+00B7 (MIDDLE DOT). Use it verbatim in code and tests.

## File Structure

- **Create** `Sources/WorldCupBar/App/AppVersion.swift` — bundle reader + pure `footerText(...)` formatter. One responsibility: turn version facts into the footer string.
- **Create** `Tests/WorldCupBarTests/AppVersionTests.swift` — unit tests for the pure formatter.
- **Create** `scripts/stamp-git-info.sh` — build-phase script that writes `GitSHA`/`GitDirty` into the product Info.plist.
- **Modify** `project.yml` — add a `postBuildScripts` phase to the `WorldCupBar` target referencing that script.
- **Modify** `Sources/WorldCupBar/Settings/SettingsView.swift` — wrap the sidebar `List` in a `VStack` and add the footer.

---

### Task 1: Pure version formatter + bundle reader

**Files:**
- Create: `Sources/WorldCupBar/App/AppVersion.swift`
- Test: `Tests/WorldCupBarTests/AppVersionTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `Tests/WorldCupBarTests/AppVersionTests.swift`:

```swift
import Testing
@testable import WorldCupBar

@Test func footerReleaseHidesGitDetail() {
    let text = AppVersion.footerText(
        version: "1.1.1", build: "42", sha: "90ed77e", dirty: true, isDebug: false
    )
    #expect(text == "v1.1.1 (build 42)")
}

@Test func footerDebugCleanShowsSha() {
    let text = AppVersion.footerText(
        version: "1.1.1", build: "1", sha: "90ed77e", dirty: false, isDebug: true
    )
    #expect(text == "v1.1.1 (build 1) · 90ed77e")
}

@Test func footerDebugDirtyAppendsDirty() {
    let text = AppVersion.footerText(
        version: "1.1.1", build: "1", sha: "90ed77e", dirty: true, isDebug: true
    )
    #expect(text == "v1.1.1 (build 1) · 90ed77e-dirty")
}

@Test func footerDebugUnknownShaWhenNoGit() {
    let text = AppVersion.footerText(
        version: "1.1.1", build: "1", sha: "unknown", dirty: false, isDebug: true
    )
    #expect(text == "v1.1.1 (build 1) · unknown")
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `swift test 2>&1 | tail -20`
Expected: FAIL — compile error, `cannot find 'AppVersion' in scope`.

- [ ] **Step 3: Implement `AppVersion`**

Create `Sources/WorldCupBar/App/AppVersion.swift`:

```swift
import Foundation

/// Version + git build metadata read from the app bundle, plus the pure
/// formatting logic for the Settings footer. Keeping `footerText` pure (no
/// bundle, no view) makes the composition unit-testable.
struct AppVersion {
    let version: String
    let build: String
    let sha: String
    let dirty: Bool

    static func fromBundle(_ bundle: Bundle = .main) -> AppVersion {
        func string(_ key: String, default def: String) -> String {
            (bundle.object(forInfoDictionaryKey: key) as? String) ?? def
        }
        let dirtyValue = bundle.object(forInfoDictionaryKey: "GitDirty")
        let dirty = (dirtyValue as? Bool) ?? ((dirtyValue as? String) == "true")
        return AppVersion(
            version: string("CFBundleShortVersionString", default: "0.0.0"),
            build: string("CFBundleVersion", default: "0"),
            sha: string("GitSHA", default: "unknown"),
            dirty: dirty
        )
    }

    /// Pure formatter. `isDebug` decides whether git detail is appended;
    /// Release builds get the clean `v{version} (build {build})` form.
    static func footerText(
        version: String, build: String, sha: String, dirty: Bool, isDebug: Bool
    ) -> String {
        let base = "v\(version) (build \(build))"
        guard isDebug else { return base }
        return "\(base) · \(sha)\(dirty ? "-dirty" : "")"
    }

    /// Bundle-derived footer string with build-config gating baked in.
    var footer: String {
        #if DEBUG
        return Self.footerText(version: version, build: build, sha: sha, dirty: dirty, isDebug: true)
        #else
        return Self.footerText(version: version, build: build, sha: sha, dirty: dirty, isDebug: false)
        #endif
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test 2>&1 | tail -20`
Expected: PASS — test count goes from 45 to **49** ("Test run with 49 tests ... passed").

- [ ] **Step 5: Lint**

Run: `swiftlint lint --strict`
Expected: no violations.

- [ ] **Step 6: Commit**

```bash
git add Sources/WorldCupBar/App/AppVersion.swift Tests/WorldCupBarTests/AppVersionTests.swift
git commit -m "feat(settings): add AppVersion reader and footer formatter

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Render the footer in the Settings sidebar

**Files:**
- Modify: `Sources/WorldCupBar/Settings/SettingsView.swift:11-33` (the `body` / sidebar)

No unit test (SwiftUI view); verified by compiling and by manual UAT.

- [ ] **Step 1: Wrap the sidebar List in a VStack and add the footer**

In `Sources/WorldCupBar/Settings/SettingsView.swift`, replace the `NavigationSplitView { ... }` sidebar closure. Change:

```swift
        NavigationSplitView {
            List(SettingsPanel.allCases, id: \.self, selection: $selectedPanel) { panel in
                Label(panel.title, systemImage: panel.icon)
                    .foregroundStyle(Color.primary)
                    .tag(panel)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(WCBVibrancyBackground().ignoresSafeArea())
        } detail: {
```

to:

```swift
        NavigationSplitView {
            VStack(spacing: 0) {
                List(SettingsPanel.allCases, id: \.self, selection: $selectedPanel) { panel in
                    Label(panel.title, systemImage: panel.icon)
                        .foregroundStyle(Color.primary)
                        .tag(panel)
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)

                versionFooter
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
            .background(WCBVibrancyBackground().ignoresSafeArea())
        } detail: {
```

- [ ] **Step 2: Add the `versionFooter` view**

In the same file, inside `struct SettingsView`, add this computed property immediately after the `body` property (after its closing `}`, before `detailContent`):

```swift
    private var versionFooter: some View {
        VStack(spacing: 0) {
            Divider()
            Text(AppVersion.fromBundle().footer)
                .font(WCBFont.caption)
                .foregroundStyle(WCBColor.secondaryLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, WCBSpacing.medium)
                .padding(.vertical, WCBSpacing.small)
        }
    }
```

- [ ] **Step 3: Regenerate the Xcode project and build**

```bash
xcodegen generate
xcodebuild -scheme WorldCupBar -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Confirm tests still pass and lint is clean**

```bash
swift test 2>&1 | tail -3
swiftlint lint --strict
```

Expected: 49 tests pass; 0 lint violations.

- [ ] **Step 5: Commit**

```bash
git add Sources/WorldCupBar/Settings/SettingsView.swift WorldCupBar.xcodeproj 2>/dev/null; git add Sources/WorldCupBar/Settings/SettingsView.swift
git commit -m "feat(settings): show version footer at bottom of sidebar

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

(Note: `WorldCupBar.xcodeproj` is gitignored; the `git add` of it is a harmless no-op kept so the command is copy-paste safe.)

---

### Task 3: Stamp git SHA + dirty flag into the built Info.plist

**Files:**
- Create: `scripts/stamp-git-info.sh`
- Modify: `project.yml` (add `postBuildScripts` to the `WorldCupBar` target, after its `settings:` block ending at line 54)

- [ ] **Step 1: Create the build-phase script**

Create `scripts/stamp-git-info.sh`:

```sh
#!/bin/sh
# Stamps the git short SHA and a "dirty" flag into the built app's Info.plist so
# the Settings footer can identify local builds. Runs as a post-build phase
# (after Info.plist processing, before code signing). Never fails the build.
set -u

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
SHA="$(git -C "${SRCROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"

# "dirty" = uncommitted changes to build inputs (Sources, project.yml).
# Untracked docs and gitignored artifacts (.build, dist, *.xcodeproj) don't count.
if [ -n "$(git -C "${SRCROOT}" status --porcelain -- Sources project.yml 2>/dev/null)" ]; then
  DIRTY=true
else
  DIRTY=false
fi

if [ ! -f "${PLIST}" ]; then
  echo "warning: Info.plist not found at ${PLIST}; skipping git stamp"
  exit 0
fi

/usr/libexec/PlistBuddy -c "Add :GitSHA string ${SHA}" "${PLIST}" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :GitSHA ${SHA}" "${PLIST}" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :GitDirty bool ${DIRTY}" "${PLIST}" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :GitDirty ${DIRTY}" "${PLIST}" 2>/dev/null || true

echo "Stamped GitSHA=${SHA} GitDirty=${DIRTY} into ${PLIST}"
```

Then make it executable:

```bash
chmod +x scripts/stamp-git-info.sh
```

- [ ] **Step 2: Wire the script into the WorldCupBar target**

In `project.yml`, add a `postBuildScripts` key to the `WorldCupBar` target, as a sibling of `settings:` (4-space indent). Insert it immediately after the `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` line that ends the target's `settings.base` block:

```yaml
    postBuildScripts:
      - name: Stamp git revision into Info.plist
        path: scripts/stamp-git-info.sh
        basedOnDependencyAnalysis: false
```

`basedOnDependencyAnalysis: false` makes it run on every build so the SHA/dirty stay current. `postBuildScripts` runs after Info.plist processing and before code signing, so the modified plist is sealed by the signature.

- [ ] **Step 3: Regenerate and build**

```bash
xcodegen generate
xcodebuild -scheme WorldCupBar -configuration Debug build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`, and the build log includes a line `Stamped GitSHA=... GitDirty=...`.

- [ ] **Step 4: Verify the keys landed in the product Info.plist and the signature is valid**

```bash
APP="$(xcodebuild -scheme WorldCupBar -configuration Debug -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR /{d=$2} / FULL_PRODUCT_NAME /{n=$2} END{print d"/"n}')"
echo "App: $APP"
/usr/libexec/PlistBuddy -c 'Print :GitSHA'   "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :GitDirty' "$APP/Contents/Info.plist"
codesign --verify --strict "$APP" && echo "signature OK"
```

Expected: `GitSHA` prints a short hash (e.g. `90ed77e`) — **not** empty/absent; `GitDirty` prints `true` (project.yml is uncommitted at this point) or `false`; `signature OK`.

**If `GitSHA` is absent** (Info.plist not processed when the script ran): change `postBuildScripts` to `postCompileScripts` in `project.yml`, re-run Step 3, and re-verify. (Both run before signing; `postCompileScripts` runs earlier.)

- [ ] **Step 5: Commit**

```bash
git add scripts/stamp-git-info.sh project.yml
git commit -m "build(settings): stamp git sha/dirty into Info.plist for version footer

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Whole-feature verification

**Files:** none (verification only)

- [ ] **Step 1: Full fast test + lint**

```bash
swift test 2>&1 | tail -3
swiftlint lint --strict
```

Expected: 49 tests pass; 0 violations.

- [ ] **Step 2: Full Xcode test pass**

```bash
xcodebuild -scheme WorldCupBar -destination 'platform=macOS' test 2>&1 | tail -5
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 3: Manual UAT (developer)**

Run the Debug app (`⌘R` in `WorldCupBar.xcodeproj`), open Settings, and confirm the footer at the bottom of the sidebar reads e.g. `v1.0.0 (build 1) · 90ed77e-dirty`. (User performs this; not scriptable here.)

---

## Self-Review

**Spec coverage** — every spec section maps to a task:
- Behavior table (release clean / debug+sha / debug+dirty / no-git) → Task 1 formatter + tests (Step 1/3), gated by `#if DEBUG` in `AppVersion.footer`.
- "dirty" = uncommitted build-input changes → Task 3 script (`git status --porcelain -- Sources project.yml`).
- Build-time injection into the **product** plist, graceful degradation, ordering-before-signing → Task 3 (script + `postBuildScripts` + Step 4 verification incl. the fallback to `postCompileScripts`).
- `AppVersion` reader + pure formatter (testable seam) → Task 1.
- Sidebar bottom-left footer via `VStack`, theme tokens → Task 2.
- Tests for the formatter → Task 1 Step 1.

**Placeholder scan** — no TBD/"handle edge cases"; every code step shows full code; every command has an expected result; the one conditional (plist-missing) is concrete and verifiable.

**Type/signature consistency** — `AppVersion.footerText(version:build:sha:dirty:isDebug:)` is identical across Task 1 (def), Task 1 tests, and `AppVersion.footer`. `AppVersion.fromBundle()` / `.footer` used consistently in Task 2. Info.plist keys `GitSHA` (String) / `GitDirty` (Bool) match between the Task 3 script (writer) and the Task 1 reader.
