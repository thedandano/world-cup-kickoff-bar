# Configurable "vs" Mark Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users pick one of four drawn "vs" marks (italic / ring / slash / clash) in Settings, and render the chosen mark between teams in the menu bar, the hero "Up next" row, and every match row in the tab lists.

**Architecture:** A pure `VSMarkStyle` enum in `WorldCupBarCore` (mirrors the existing `DisplayMode`). The `WorldCupBarViewModel` owns the persisted selection (UserDefaults, injected for testability). A single reusable SwiftUI `VSMark` view draws each style natively (no SVG at runtime), with color delegated to the caller via `.foregroundStyle` and a `compact` flag for single-line contexts. The menu bar gets a structured `MenuBarLabelContent` accessor so the label can compose `[home] mark [away] time` without leaking formatting into the view.

**Tech Stack:** Swift 6, SwiftPM, SwiftUI, Swift Testing (`@Test`/`#expect`). Default mark = `.ring`. Static only (no animation).

---

## File Structure

| File | Responsibility | Action |
|------|----------------|--------|
| `Sources/WorldCupBarCore/VSMarkStyle.swift` | The style enum (pure value) | Create |
| `Sources/WorldCupBar/VSMark.swift` | SwiftUI view that draws the 4 marks | Create |
| `Sources/WorldCupBarCore/MatchFormatter.swift` | Add public `teamLabel(for:displayMode:)` | Modify |
| `Sources/WorldCupBar/WorldCupBarViewModel.swift` | Inject UserDefaults; add `vsMarkStyle`; add `menuBarLabel` + `MenuBarLabelContent` | Modify |
| `Sources/WorldCupBar/SettingsView.swift` | Add the mark picker to `DisplayPanel` | Modify |
| `Sources/WorldCupBar/MenuBarDropdownView.swift` | Swap hero `Text("vs")`; restructure `MatchRow` | Modify |
| `Sources/WorldCupBar/WorldCupBarApp.swift` | Compose the menu-bar label with the mark | Modify |
| `Tests/WorldCupBarCoreTests/VSMarkStyleTests.swift` | Enum + formatter tests | Create |
| `Tests/WorldCupBarTests/WorldCupBarViewModelTests.swift` | Persistence + `menuBarLabel` tests | Modify |

**Slices:** Slice 1 = Tasks 1–5 (configurable + visible in popover hero). Slice 2 = Task 6 (tab rows). Slice 3 = Tasks 7–9 (menu bar).

---

### Task 1: `VSMarkStyle` enum (Core)

**Files:**
- Create: `Sources/WorldCupBarCore/VSMarkStyle.swift`
- Test: `Tests/WorldCupBarCoreTests/VSMarkStyleTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/WorldCupBarCoreTests/VSMarkStyleTests.swift`:

```swift
import Testing
import WorldCupBarCore

@Test func vsMarkStyleHasFourCases() {
    #expect(VSMarkStyle.allCases.count == 4)
}

@Test func vsMarkStyleRoundTripsThroughRawValue() {
    for style in VSMarkStyle.allCases {
        #expect(VSMarkStyle(rawValue: style.rawValue) == style)
    }
}

@Test func vsMarkStyleDisplayNamesAreNonEmpty() {
    for style in VSMarkStyle.allCases {
        #expect(!style.displayName.isEmpty)
    }
}

@Test func vsMarkStyleDefaultRawValuesAreStable() {
    #expect(VSMarkStyle.italic.rawValue == "italic")
    #expect(VSMarkStyle.ring.rawValue == "ring")
    #expect(VSMarkStyle.slash.rawValue == "slash")
    #expect(VSMarkStyle.clash.rawValue == "clash")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter vsMarkStyle`
Expected: build failure — `cannot find 'VSMarkStyle' in scope`.

- [ ] **Step 3: Write minimal implementation**

Create `Sources/WorldCupBarCore/VSMarkStyle.swift`:

```swift
/// The drawn "vs" mark shown between two teams. Persisted as `rawValue`.
public enum VSMarkStyle: String, CaseIterable, Codable, Equatable, Sendable {
    case italic
    case ring
    case slash
    case clash

    public var displayName: String {
        switch self {
        case .italic: return "Italic"
        case .ring:   return "Ring"
        case .slash:  return "Slash"
        case .clash:  return "Clash"
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter vsMarkStyle`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add Sources/WorldCupBarCore/VSMarkStyle.swift Tests/WorldCupBarCoreTests/VSMarkStyleTests.swift
git commit -m "feat(core): add VSMarkStyle enum for the vs mark picker"
```

---

### Task 2: Inject UserDefaults + add `vsMarkStyle` (ViewModel)

**Files:**
- Modify: `Sources/WorldCupBar/WorldCupBarViewModel.swift`
- Test: `Tests/WorldCupBarTests/WorldCupBarViewModelTests.swift`

This injects a `UserDefaults` into the view model (default `.standard`, so the app is unchanged) so persistence can be tested in an isolated suite — honoring the project rule "never use `UserDefaults.standard` in tests."

- [ ] **Step 1: Write the failing test**

Append to `Tests/WorldCupBarTests/WorldCupBarViewModelTests.swift` (before the `private struct StubRepository` declaration):

```swift
@MainActor
@Test func vsMarkStyleDefaultsToRing() {
    let suite = "vsMarkTest-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    let viewModel = WorldCupBarViewModel(
        repository: StubRepository(cachedSnapshot: nil, refreshedSnapshot: nil),
        analytics: StubAnalytics(),
        notificationScheduler: StubNotificationScheduler(),
        defaults: defaults
    )

    #expect(viewModel.vsMarkStyle == .ring)
}

@MainActor
@Test func vsMarkStylePersistsAcrossViewModels() {
    let suite = "vsMarkTest-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    let first = WorldCupBarViewModel(
        repository: StubRepository(cachedSnapshot: nil, refreshedSnapshot: nil),
        analytics: StubAnalytics(),
        notificationScheduler: StubNotificationScheduler(),
        defaults: defaults
    )
    first.vsMarkStyle = .clash

    let second = WorldCupBarViewModel(
        repository: StubRepository(cachedSnapshot: nil, refreshedSnapshot: nil),
        analytics: StubAnalytics(),
        notificationScheduler: StubNotificationScheduler(),
        defaults: defaults
    )

    #expect(second.vsMarkStyle == .clash)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter vsMarkStyle`
Expected: build failure — `WorldCupBarViewModel` has no `defaults:` parameter and no `vsMarkStyle` member.

- [ ] **Step 3: Implement — inject `defaults`**

In `Sources/WorldCupBar/WorldCupBarViewModel.swift`, add a stored property next to the other `private let` dependencies (after `private let notificationScheduler: any NotificationScheduling`):

```swift
    private let defaults: UserDefaults
```

Change the four `didSet` writers to use `defaults` instead of `UserDefaults.standard`:
- `UserDefaults.standard.set(displayMode.rawValue, ...)` → `defaults.set(displayMode.rawValue, ...)`
- `UserDefaults.standard.set(Array(followedCountryCodes)..., ...)` → `defaults.set(Array(followedCountryCodes)..., ...)`
- `UserDefaults.standard.set(analyticsEnabled, ...)` → `defaults.set(analyticsEnabled, ...)`
- `UserDefaults.standard.set(notificationMinutesBefore, ...)` → `defaults.set(notificationMinutesBefore, ...)`

Update the `init` signature to add the parameter (keep the default):

```swift
    init(
        repository: any WorldCupDataProviding,
        analytics: any WorldCupAnalyticsTracking,
        notificationScheduler: any NotificationScheduling = NotificationScheduler.shared,
        defaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.analytics = analytics
        self.notificationScheduler = notificationScheduler
        self.defaults = defaults
```

Change the four reads in `init` from `UserDefaults.standard` to `defaults`:
- `UserDefaults.standard.string(forKey: UserDefaultsKeys.displayMode)` → `defaults.string(forKey: UserDefaultsKeys.displayMode)`
- `UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.followedCountryCodes)` → `defaults.stringArray(forKey: UserDefaultsKeys.followedCountryCodes)`
- `UserDefaults.standard.object(forKey: UserDefaultsKeys.analyticsEnabled)` → `defaults.object(forKey: UserDefaultsKeys.analyticsEnabled)`
- `UserDefaults.standard.object(forKey: UserDefaultsKeys.notificationMinutesBefore)` → `defaults.object(forKey: UserDefaultsKeys.notificationMinutesBefore)`

- [ ] **Step 4: Implement — add `vsMarkStyle`**

Add the published property next to `displayMode` (after the `displayMode` block, before `followedCountryCodes`):

```swift
    var vsMarkStyle: VSMarkStyle {
        didSet {
            defaults.set(vsMarkStyle.rawValue, forKey: UserDefaultsKeys.vsMarkStyle)
            analytics.recordUserAction("vs_mark_style_changed", properties: ["style": vsMarkStyle.rawValue])
        }
    }
```

Add the init load (place next to the `storedDisplayMode` load, after `self.displayMode = storedDisplayMode ?? .abbreviations`):

```swift
        let storedVSMarkStyle = defaults.string(forKey: UserDefaultsKeys.vsMarkStyle)
            .flatMap(VSMarkStyle.init(rawValue:))
        self.vsMarkStyle = storedVSMarkStyle ?? .ring
```

Add the key to the `UserDefaultsKeys` enum (after `static let displayMode = "displayMode"`):

```swift
    static let vsMarkStyle = "vsMarkStyle"
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `swift test --filter vsMarkStyle`
Expected: PASS. Then run the full view-model suite to confirm no regression:
Run: `swift test --filter WorldCupBarViewModel`
Expected: PASS (existing tests still green — they use the `.standard` default).

- [ ] **Step 6: Commit**

```bash
git add Sources/WorldCupBar/WorldCupBarViewModel.swift Tests/WorldCupBarTests/WorldCupBarViewModelTests.swift
git commit -m "feat(menu): persist a configurable vsMarkStyle on the view model"
```

---

### Task 3: `VSMark` SwiftUI view

**Files:**
- Create: `Sources/WorldCupBar/VSMark.swift`

No unit test (SwiftUI view); verified by `swift build`. Color is inherited from the caller's `.foregroundStyle`; geometry is intrinsic to the glyph.

- [ ] **Step 1: Implement the view**

Create `Sources/WorldCupBar/VSMark.swift`:

```swift
import SwiftUI
import WorldCupBarCore

/// A drawn "vs" mark shown between two teams. Color is inherited from the
/// caller's `.foregroundStyle`; `size` sets the glyph height in points.
/// `compact` switches the tall `clash` mark to a single-line layout for the
/// menu bar and list rows.
struct VSMark: View {
    let style: VSMarkStyle
    var size: CGFloat = 20
    var compact: Bool = false

    var body: some View {
        switch style {
        case .italic:
            Text("vs")
                .font(.system(size: size, weight: .regular, design: .serif))
                .italic()
        case .ring:
            ZStack {
                Circle()
                    .strokeBorder(lineWidth: max(1.2, size * 0.07))
                Text("VS")
                    .font(.system(size: size * 0.42, weight: .bold))
            }
            .frame(width: size, height: size)
        case .slash:
            HStack(spacing: size * 0.04) {
                Text("v").font(.system(size: size, weight: .medium))
                slash(height: size * 0.95, thickness: max(1.5, size * 0.08))
                Text("s").font(.system(size: size, weight: .medium))
            }
        case .clash:
            if compact {
                clashCompact
            } else {
                clashMark
            }
        }
    }

    private var clashMark: some View {
        ZStack {
            Text("V")
                .font(.system(size: size, weight: .heavy))
                .offset(x: -size * 0.28, y: -size * 0.21)
            Text("S")
                .font(.system(size: size, weight: .heavy))
                .offset(x: size * 0.28, y: size * 0.21)
            slash(height: size * 1.40, thickness: max(2, size * 0.10))
        }
        .frame(width: size * 1.5, height: size * 1.6)
    }

    private var clashCompact: some View {
        HStack(spacing: size * 0.04) {
            Text("V").font(.system(size: size, weight: .heavy))
            slash(height: size * 1.05, thickness: max(1.5, size * 0.09))
            Text("S").font(.system(size: size, weight: .heavy))
        }
    }

    private func slash(height: CGFloat, thickness: CGFloat) -> some View {
        Capsule()
            .frame(width: thickness, height: height)
            .rotationEffect(.degrees(18))
    }
}

#Preview {
    HStack(spacing: 24) {
        ForEach(VSMarkStyle.allCases, id: \.self) { style in
            VStack(spacing: 8) {
                VSMark(style: style, size: 30)
                Text(style.displayName).font(.caption)
            }
        }
    }
    .foregroundStyle(.purple)
    .padding(40)
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `swift build`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/WorldCupBar/VSMark.swift
git commit -m "feat(menu): add VSMark view rendering the four vs styles"
```

---

### Task 4: Settings picker

**Files:**
- Modify: `Sources/WorldCupBar/SettingsView.swift` (`DisplayPanel`)

Adds a second card to the existing Display panel: a segmented picker over the four styles plus a live preview of the current mark. Verified by `swift build`.

- [ ] **Step 1: Implement the picker card**

In `DisplayPanel.body`, the `PanelScrollView` currently wraps a single `SettingsCard`. Add a second `SettingsCard` immediately after the existing one (still inside the `PanelScrollView` closure):

```swift
            SettingsCard {
                HStack(alignment: .center, spacing: WCBSpacing.lg) {
                    VStack(alignment: .leading, spacing: WCBSpacing.xs) {
                        Text("Match separator")
                            .font(WCBFont.rowPrimary)
                        Text("The “vs” mark shown between teams.")
                            .font(WCBFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VSMark(style: viewModel.vsMarkStyle, size: 24)
                        .foregroundStyle(WCBColor.accent)
                        .frame(width: 44, height: 34)
                    Picker("Match separator", selection: $viewModel.vsMarkStyle) {
                        ForEach(VSMarkStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .tint(WCBColor.accent)
                    .frame(width: 250)
                    .help("Choose the mark drawn between the two teams.")
                }
                .padding(WCBSpacing.md)
            }
```

- [ ] **Step 2: Build to verify it compiles**

Run: `swift build`
Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/WorldCupBar/SettingsView.swift
git commit -m "feat(settings): add a vs mark picker to the Display panel"
```

---

### Task 5: Hero "Up next" mark (Slice 1 end)

**Files:**
- Modify: `Sources/WorldCupBar/MenuBarDropdownView.swift` (`HeroMatchRow` + call site)

- [ ] **Step 1: Add `style` to `HeroMatchRow` and swap the literal**

In `HeroMatchRow`, add the stored property below `let showLivePill: Bool`:

```swift
    let style: VSMarkStyle
```

Replace the `else` branch that renders `Text("vs")`:

```swift
                } else {
                    Text("vs")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(WCBColor.secondaryLabel)
                        .tracking(1)
                }
```

with:

```swift
                } else {
                    VSMark(style: style, size: 22)
                        .foregroundStyle(WCBColor.secondaryLabel)
                }
```

- [ ] **Step 2: Update the call site**

In `highlightedMatchSection`, update the `HeroMatchRow(...)` initializer to pass the style:

```swift
                HeroMatchRow(
                    match: match,
                    centerText: centerStatusText(for: match),
                    showLivePill: match.status.isLive,
                    style: viewModel.vsMarkStyle
                )
```

- [ ] **Step 3: Build to verify it compiles**

Run: `swift build`
Expected: `Build complete!`

- [ ] **Step 4: Run the full test suite**

Run: `swift test`
Expected: PASS (all existing + new tests).

- [ ] **Step 5: Commit**

```bash
git add Sources/WorldCupBar/MenuBarDropdownView.swift
git commit -m "feat(menu): render the selected vs mark in the hero row"
```

---

### Task 6: Tab list rows (Slice 2)

**Files:**
- Modify: `Sources/WorldCupBar/MenuBarDropdownView.swift` (`MatchRow` + `matchList` call site)

Replaces the single truncated `🇺🇸 USA - 🇲🇽 MEX` string with a composed `[flag+code] VSMark [flag+code]` so the mark appears between teams. The `title` parameter is removed.

- [ ] **Step 1: Restructure `MatchRow`**

Replace the `MatchRow` struct's stored properties:

```swift
private struct MatchRow: View {
    let match: WorldCupMatch
    let title: String
    let time: String
```

with:

```swift
private struct MatchRow: View {
    let match: WorldCupMatch
    let style: VSMarkStyle
    let time: String
```

In `MatchRow.body`, replace the first child of the leading `VStack` — the `Text(title)` block:

```swift
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
```

with a composed matchup row:

```swift
                HStack(spacing: 6) {
                    teamLabel(match.home)
                    VSMark(style: style, size: 12, compact: true)
                        .foregroundStyle(WCBColor.secondaryLabel)
                    teamLabel(match.away)
                }
                .lineLimit(1)
```

Add this helper inside `MatchRow` (after `body`):

```swift
    @ViewBuilder
    private func teamLabel(_ country: Country) -> some View {
        HStack(spacing: 4) {
            if country.hasRenderableFlag {
                Text(country.flagEmoji)
            }
            Text(country.code)
                .font(.system(size: 13, weight: .medium))
        }
    }
```

- [ ] **Step 2: Update the `matchList` call site**

In `matchList(for:)`, update the `MatchRow(...)` initializer:

```swift
                    MatchRow(
                        match: match,
                        title: viewModel.dropdownMatchupTitle(for: match),
                        time: viewModel.scheduledTime(for: match.kickoffDate)
                    )
```

to:

```swift
                    MatchRow(
                        match: match,
                        style: viewModel.vsMarkStyle,
                        time: viewModel.scheduledTime(for: match.kickoffDate)
                    )
```

- [ ] **Step 3: Build to verify it compiles**

Run: `swift build`
Expected: `Build complete!` (`dropdownMatchupTitle` remains defined and is still used by `highlightTitle`, so no dead-code break.)

- [ ] **Step 4: Commit**

```bash
git add Sources/WorldCupBar/MenuBarDropdownView.swift
git commit -m "feat(menu): show the vs mark between teams in tab list rows"
```

---

### Task 7: Formatter `teamLabel` (Core)

**Files:**
- Modify: `Sources/WorldCupBarCore/MatchFormatter.swift`
- Test: `Tests/WorldCupBarCoreTests/VSMarkStyleTests.swift`

A public helper that returns one team's menu-bar label (code, or flag-with-code fallback) — the per-team equivalent of the private logic inside `matchupTitle`.

- [ ] **Step 1: Write the failing test**

Append to `Tests/WorldCupBarCoreTests/VSMarkStyleTests.swift`:

```swift
@Test func teamLabelUsesCodeInAbbreviationsMode() {
    let formatter = MatchFormatter()
    #expect(formatter.teamLabel(for: .unitedStates, displayMode: .abbreviations) == "USA")
}

@Test func teamLabelFallsBackToCodeWhenNoRenderableFlag() {
    let formatter = MatchFormatter()
    let country = Country.unitedStates
    let expected = country.hasRenderableFlag ? country.flagEmoji : country.code
    #expect(formatter.teamLabel(for: country, displayMode: .flags) == expected)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter teamLabel`
Expected: build failure — `MatchFormatter` has no member `teamLabel`.

- [ ] **Step 3: Implement**

In `Sources/WorldCupBarCore/MatchFormatter.swift`, add this public method directly after `matchupTitle(for:displayMode:)`:

```swift
    public func teamLabel(for country: Country, displayMode: DisplayMode) -> String {
        switch displayMode {
        case .abbreviations:
            return country.code
        case .flags:
            return flagOrCode(for: country)
        }
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter teamLabel`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add Sources/WorldCupBarCore/MatchFormatter.swift Tests/WorldCupBarCoreTests/VSMarkStyleTests.swift
git commit -m "feat(core): add MatchFormatter.teamLabel for per-team menu-bar labels"
```

---

### Task 8: `menuBarLabel` accessor (ViewModel)

**Files:**
- Modify: `Sources/WorldCupBar/WorldCupBarViewModel.swift`
- Test: `Tests/WorldCupBarTests/WorldCupBarViewModelTests.swift`

A structured menu-bar accessor so the view can compose `[home] mark [away] time` for upcoming matches and fall back to the existing string for every other state.

- [ ] **Step 1: Write the failing test**

Append to `Tests/WorldCupBarTests/WorldCupBarViewModelTests.swift` (before `private struct StubRepository`):

```swift
@MainActor
@Test func menuBarLabelIsMatchupForUpcomingSpotlight() async {
    let suite = "vsMarkTest-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    let future = Date(timeIntervalSinceNow: 3_600)
    let snapshot = WorldCupSnapshot(
        matches: [
            WorldCupMatch(id: "m1", home: .unitedStates, away: .brazil,
                          kickoffDate: future, status: .scheduled, score: nil, venue: "MetLife Stadium")
        ],
        countries: Country.previewDefaults,
        fetchedAt: Date()
    )
    let viewModel = WorldCupBarViewModel(
        repository: StubRepository(cachedSnapshot: nil, refreshedSnapshot: snapshot),
        analytics: StubAnalytics(),
        notificationScheduler: StubNotificationScheduler(),
        defaults: defaults
    )

    await viewModel.start()
    viewModel.followedCountryCodes = ["USA"]

    guard case let .matchup(home, away, _) = viewModel.menuBarLabel else {
        Issue.record("Expected .matchup, got \(viewModel.menuBarLabel)")
        return
    }
    #expect(home == Country.unitedStates.code)
    #expect(away == Country.brazil.code)
}

@MainActor
@Test func menuBarLabelIsTextForPostTournament() async {
    let suite = "vsMarkTest-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    let snapshot = WorldCupSnapshot(
        matches: [
            WorldCupMatch(id: "final", home: .argentina, away: .france,
                          kickoffDate: Date(timeIntervalSince1970: 1_799_900_000),
                          status: .finished, score: MatchScore(home: 3, away: 2), venue: "MetLife Stadium")
        ],
        countries: Country.previewDefaults,
        fetchedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
    let viewModel = WorldCupBarViewModel(
        repository: StubRepository(cachedSnapshot: snapshot, refreshedSnapshot: snapshot),
        analytics: StubAnalytics(),
        notificationScheduler: StubNotificationScheduler(),
        defaults: defaults
    )

    await viewModel.start()

    #expect(viewModel.menuBarLabel == .text("See you in 2030!"))
}
```

> Note: `.brazil`'s code is `"BRA"`. The matchup test asserts only the case + team labels (not the time string, which is locale/timezone dependent).

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter menuBarLabel`
Expected: build failure — no `menuBarLabel` member / no `MenuBarLabelContent` type.

- [ ] **Step 3: Implement the accessor**

In `Sources/WorldCupBar/WorldCupBarViewModel.swift`, add this computed property directly after the existing `menuBarTitle` computed property (which it reuses):

```swift
    var menuBarLabel: MenuBarLabelContent {
        guard case .content = contentState, case .upcoming(let match) = displayState else {
            return .text(menuBarTitle)
        }
        return .matchup(
            home: formatter.teamLabel(for: match.home, displayMode: displayMode),
            away: formatter.teamLabel(for: match.away, displayMode: displayMode),
            detail: formatter.localTime(for: match.kickoffDate)
        )
    }
```

Add the type at file scope, directly after the `enum WorldCupContentState { ... }` declaration near the bottom of the file:

```swift
enum MenuBarLabelContent: Equatable {
    case text(String)
    case matchup(home: String, away: String, detail: String)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter menuBarLabel`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add Sources/WorldCupBar/WorldCupBarViewModel.swift Tests/WorldCupBarTests/WorldCupBarViewModelTests.swift
git commit -m "feat(menu): expose structured menuBarLabel for the menu-bar mark"
```

---

### Task 9: Menu-bar label composition (Slice 3 end)

**Files:**
- Modify: `Sources/WorldCupBar/WorldCupBarApp.swift`

Replaces the plain-text menu-bar label with a small view that draws the mark between team labels for upcoming matches and keeps the existing string for all other states. Default mark color is inherited (primary), so it adapts to light/dark menu bars exactly like the old `Text`.

- [ ] **Step 1: Swap the label content**

In `WorldCupBarApp.body`, replace the `MenuBarExtra` `label:` closure:

```swift
        } label: {
            Text(viewModel.menuBarTitle)
                .font(.system(size: 13, weight: .semibold, design: .default))
                .monospacedDigit()
                .background(OpenWindowListener())
                .task {
                    await viewModel.start()
                }
        }
```

with:

```swift
        } label: {
            MenuBarLabel(viewModel: viewModel)
                .background(OpenWindowListener())
                .task {
                    await viewModel.start()
                }
        }
```

- [ ] **Step 2: Add the `MenuBarLabel` view**

Add this private view to `WorldCupBarApp.swift`, directly above the `private struct OpenWindowListener: View` declaration:

```swift
// Composes the menu-bar label: for an upcoming spotlight it draws the selected
// vs mark between the two team labels; every other state keeps the plain title.
private struct MenuBarLabel: View {
    var viewModel: WorldCupBarViewModel

    var body: some View {
        Group {
            switch viewModel.menuBarLabel {
            case .text(let title):
                Text(title)
            case .matchup(let home, let away, let detail):
                HStack(spacing: 4) {
                    Text(home)
                    VSMark(style: viewModel.vsMarkStyle, size: 11, compact: true)
                    Text(away)
                    Text(detail)
                }
            }
        }
        .font(.system(size: 13, weight: .semibold))
        .monospacedDigit()
    }
}
```

- [ ] **Step 3: Build to verify it compiles**

Run: `swift build`
Expected: `Build complete!`

- [ ] **Step 4: Run the full test suite**

Run: `swift test`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add Sources/WorldCupBar/WorldCupBarApp.swift
git commit -m "feat(menu): draw the selected vs mark in the menu-bar label"
```

---

## Final Verification

- [ ] Run `swift build` → `Build complete!`
- [ ] Run `swift test` → all tests pass
- [ ] Run `swiftlint lint --strict` if available → no violations
- [ ] **Manual (GUI) check** — `swift build` cannot render the menu bar. Launch the app and confirm: (a) Settings ▸ Display shows the picker + live preview and switching styles updates the hero/rows live; (b) the hero "Up next" shows the chosen mark; (c) tab rows show the mark between teams; (d) the menu-bar label shows the mark for an upcoming match. If `MenuBarExtra` does not render the custom `VSMark` in the status item, fall back to mapping the style to a text separator in `MenuBarLabel` (e.g. slash → `v/s`, clash → `V/S`) — but verify first, as custom label views generally rasterize fine.

## Notes / Decisions
- **Default:** `.ring`. **Animation:** none (static).
- **Colors:** menu bar inherits primary (adapts light/dark); hero + rows use `WCBColor.secondaryLabel` to match today's understated look. One-line change to `WCBColor.accent` if a bolder lavender mark is wanted.
- **`VSMark` geometry** (offsets, slash angle) is intrinsic to the glyph, not theme spacing — kept as explicit ratios. Color is the only theme-governed value and is delegated to the caller via `.foregroundStyle`.
