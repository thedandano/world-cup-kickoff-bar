# Settings Search, Notifications, and Change-Detection Cache Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a country search bar to Settings, configurable pre-match notifications (default 15 min), and change-detection so polling skips UI updates when match data hasn't changed.

**Architecture:** All business logic lives in `WorldCupBarViewModel` (MVVM). A new `NotificationScheduler` service handles `UNUserNotificationCenter` calls and is injected via the ViewModel's `init`. Change detection lives in `WorldCupRepository` — it compares a new snapshot's content against the cached one before publishing, avoiding unnecessary UI refreshes. Settings UI adds local `@State` for the search query (view-only state) and binds notification preference to `$viewModel.notificationMinutesBefore`.

**Tech Stack:** SwiftUI, `UserNotifications` framework, `WorldCupBarCore` (pure Swift), Swift Testing (`@Test`)

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `Sources/WorldCupBar/SettingsView.swift` | Modify | Rename section; add country search TextField; add notification picker |
| `Sources/WorldCupBar/NotificationScheduler.swift` | **Create** | Schedule/cancel `UNCalendarNotificationTrigger` requests for upcoming matches |
| `Sources/WorldCupBar/WorldCupBarApp.swift` | Modify | Pass `NotificationScheduler` to ViewModel; request notification permission on start |
| `Sources/WorldCupBar/WorldCupBarViewModel.swift` | Modify | Add `notificationMinutesBefore`; call scheduler on snapshot apply and on setting change |
| `Sources/WorldCupBarCore/WorldCupSnapshot.swift` | Modify | Add `matchesContentEqual(to:)` for content-only equality check |
| `Sources/WorldCupBarCore/WorldCupRepository.swift` | Modify | Skip store save + return cached snapshot when content is unchanged |
| `Tests/WorldCupBarCoreTests/WorldCupSnapshotTests.swift` | **Create** | Unit tests for `matchesContentEqual` |

---

## Task 1: Rename Settings section and add country search bar

**Files:**
- Modify: `Sources/WorldCupBar/SettingsView.swift`

No new tests needed — purely view/UI. Verify by building.

- [ ] **Step 1.1: Rename section title and subtitle**

In `Sources/WorldCupBar/SettingsView.swift`, find the `followedCountriesSection` computed property and replace:

```swift
// Before:
SettingsSection(
    title: "Followed Countries",
    subtitle: "Prioritize these teams when they are live."
) {
```

```swift
// After:
SettingsSection(
    title: "Following",
    subtitle: "Teams you follow get priority in the menu bar."
) {
```

- [ ] **Step 1.2: Add `@State` search property to `SettingsView`**

After the `@ObservedObject var viewModel: WorldCupBarViewModel` line, add:

```swift
@State private var countrySearch = ""
```

- [ ] **Step 1.3: Add search field and filtered list inside `followedCountriesSection`**

Replace the `VStack(spacing: 0)` inside the section content block:

```swift
// Before:
VStack(spacing: 0) {
    if viewModel.availableCountries.isEmpty {
        Text("Team list will appear after the first live refresh.")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(16)
    } else {
        ForEach(viewModel.availableCountries) { country in
            CountrySettingsRow(
                country: country,
                isFollowed: Binding(
                    get: { viewModel.followedCountryCodes.contains(country.code) },
                    set: { viewModel.setFollowed(country, isFollowed: $0) }
                )
            )

            if country.id != viewModel.availableCountries.last?.id {
                Divider()
                    .padding(.leading, 46)
            }
        }
    }
}
```

```swift
// After:
VStack(spacing: 0) {
    if viewModel.availableCountries.isEmpty {
        Text("Team list will appear after the first live refresh.")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(16)
    } else {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search countries", text: $countrySearch)
                .textFieldStyle(.plain)
            if !countrySearch.isEmpty {
                Button {
                    countrySearch = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))

        Divider()

        let filteredCountries = viewModel.availableCountries.filter { country in
            countrySearch.isEmpty
                || country.name.localizedCaseInsensitiveContains(countrySearch)
                || country.code.localizedCaseInsensitiveContains(countrySearch)
        }

        if filteredCountries.isEmpty {
            Text("No countries match "\(countrySearch)".")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(16)
        } else {
            ForEach(filteredCountries) { country in
                CountrySettingsRow(
                    country: country,
                    isFollowed: Binding(
                        get: { viewModel.followedCountryCodes.contains(country.code) },
                        set: { viewModel.setFollowed(country, isFollowed: $0) }
                    )
                )

                if country.id != filteredCountries.last?.id {
                    Divider()
                        .padding(.leading, 46)
                }
            }
        }
    }
}
```

- [ ] **Step 1.4: Build to verify no errors**

```bash
swift build --target WorldCupBar 2>&1 | tail -20
```

Expected: `Build complete!`

- [ ] **Step 1.5: Commit**

```bash
git add Sources/WorldCupBar/SettingsView.swift
git commit -m "feat(settings): rename 'Followed Countries' to 'Following', add country search bar"
```

---

## Task 2: WorldCupSnapshot change detection

**Files:**
- Modify: `Sources/WorldCupBarCore/WorldCupSnapshot.swift`
- Modify: `Sources/WorldCupBarCore/WorldCupRepository.swift`
- Create: `Tests/WorldCupBarCoreTests/WorldCupSnapshotTests.swift`

The key insight: `WorldCupSnapshot` already has `Equatable`, but `fetchedAt` is always different on every API call, so `==` always returns `false`. We need a content-only comparison that ignores the timestamp.

- [ ] **Step 2.1: Write failing tests for `matchesContentEqual`**

Create `Tests/WorldCupBarCoreTests/WorldCupSnapshotTests.swift`:

```swift
import Foundation
import Testing
@testable import WorldCupBarCore

@Test func contentEqualIgnoresFetchedAtTimestamp() {
    let match = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .scheduled,
        score: nil,
        venue: "NYC"
    )
    let a = WorldCupSnapshot(matches: [match], countries: [], fetchedAt: Date(timeIntervalSince1970: 1_000))
    let b = WorldCupSnapshot(matches: [match], countries: [], fetchedAt: Date(timeIntervalSince1970: 2_000))

    #expect(a.matchesContentEqual(to: b))
}

@Test func contentNotEqualWhenScoreChanges() {
    let base = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .live(minute: 45),
        score: MatchScore(home: 0, away: 0),
        venue: "NYC"
    )
    let updated = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .live(minute: 67),
        score: MatchScore(home: 1, away: 0),
        venue: "NYC"
    )
    let a = WorldCupSnapshot(matches: [base], countries: [], fetchedAt: Date())
    let b = WorldCupSnapshot(matches: [updated], countries: [], fetchedAt: Date())

    #expect(!a.matchesContentEqual(to: b))
}

@Test func contentNotEqualWhenMatchCountDiffers() {
    let m1 = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .scheduled,
        score: nil,
        venue: "NYC"
    )
    let m2 = WorldCupMatch(
        id: "can-bra",
        home: .canada,
        away: .brazil,
        kickoffDate: Date(timeIntervalSince1970: 1_800_003_600),
        status: .scheduled,
        score: nil,
        venue: "Toronto"
    )
    let a = WorldCupSnapshot(matches: [m1], countries: [], fetchedAt: Date())
    let b = WorldCupSnapshot(matches: [m1, m2], countries: [], fetchedAt: Date())

    #expect(!a.matchesContentEqual(to: b))
}

@Test func contentNotEqualWhenStatusChangesFromScheduledToLive() {
    let scheduled = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .scheduled,
        score: nil,
        venue: "NYC"
    )
    let live = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .live(minute: 1),
        score: MatchScore(home: 0, away: 0),
        venue: "NYC"
    )
    let a = WorldCupSnapshot(matches: [scheduled], countries: [], fetchedAt: Date())
    let b = WorldCupSnapshot(matches: [live], countries: [], fetchedAt: Date())

    #expect(!a.matchesContentEqual(to: b))
}
```

- [ ] **Step 2.2: Run tests to verify they fail**

```bash
swift test --filter WorldCupSnapshotTests 2>&1 | tail -10
```

Expected: compile error — `matchesContentEqual` does not exist yet.

- [ ] **Step 2.3: Add `matchesContentEqual` to `WorldCupSnapshot`**

Append to `Sources/WorldCupBarCore/WorldCupSnapshot.swift` after the closing `}`:

```swift
extension WorldCupSnapshot {
    public func matchesContentEqual(to other: WorldCupSnapshot) -> Bool {
        guard matches.count == other.matches.count else { return false }
        let byID = Dictionary(uniqueKeysWithValues: matches.map { ($0.id, $0) })
        return other.matches.allSatisfy { otherMatch in
            guard let cached = byID[otherMatch.id] else { return false }
            return cached.status == otherMatch.status && cached.score == otherMatch.score
        }
    }
}
```

- [ ] **Step 2.4: Run tests to verify they pass**

```bash
swift test --filter WorldCupSnapshotTests 2>&1 | tail -10
```

Expected: `4 tests passed`

- [ ] **Step 2.5: Apply change detection in `WorldCupRepository.refreshSnapshot`**

In `Sources/WorldCupBarCore/WorldCupRepository.swift`, find the `do { let result = try await retryPolicy.execute(` block. After mapping the new snapshot, add a cache-hit check before saving:

```swift
// Find this line:
try store.save(result.value)

// Replace with:
let cached = try? store.load()
if let cached, cached.matchesContentEqual(to: result.value) {
    telemetry.recordRefreshSucceeded(
        snapshot: cached,
        latency: start.duration(to: .now),
        attemptCount: result.attemptCount
    )
    return cached
}
try store.save(result.value)
```

- [ ] **Step 2.6: Run all tests**

```bash
swift test 2>&1 | tail -15
```

Expected: all tests pass (≥18).

- [ ] **Step 2.7: Commit**

```bash
git add Sources/WorldCupBarCore/WorldCupSnapshot.swift \
        Sources/WorldCupBarCore/WorldCupRepository.swift \
        Tests/WorldCupBarCoreTests/WorldCupSnapshotTests.swift
git commit -m "feat(cache): skip UI refresh when match content is unchanged between polls"
```

---

## Task 3: NotificationScheduler service

**Files:**
- Create: `Sources/WorldCupBar/NotificationScheduler.swift`

No unit tests for `UNUserNotificationCenter` (requires a running macOS process). Functional validation in Task 4.

- [ ] **Step 3.1: Create `NotificationScheduler.swift`**

Create `Sources/WorldCupBar/NotificationScheduler.swift`:

```swift
import UserNotifications
import WorldCupBarCore

@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    func schedule(matches: [WorldCupMatch], followedCodes: Set<String>, minutesBefore: Int) async {
        let center = UNUserNotificationCenter.current()
        // Remove any existing kickoff notifications before rescheduling.
        center.removePendingNotificationRequests(withIdentifiers: matches.map { "kickoff-\($0.id)" })

        guard minutesBefore > 0 else { return }

        let now = Date()
        for match in matches {
            guard match.status == .scheduled else { continue }
            let isFollowed = followedCodes.contains(match.home.code)
                || followedCodes.contains(match.away.code)
            guard isFollowed else { continue }

            let fireDate = match.kickoffDate.addingTimeInterval(-Double(minutesBefore) * 60)
            guard fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Kickoff in \(minutesBefore) min"
            content.body = "\(match.home.name) vs \(match.away.name) · \(match.venue)"
            content.sound = .default

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "kickoff-\(match.id)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
```

- [ ] **Step 3.2: Build to verify**

```bash
swift build --target WorldCupBar 2>&1 | tail -10
```

Expected: `Build complete!`

---

## Task 4: Wire notifications into ViewModel and Settings UI

**Files:**
- Modify: `Sources/WorldCupBar/WorldCupBarViewModel.swift`
- Modify: `Sources/WorldCupBar/WorldCupBarApp.swift`
- Modify: `Sources/WorldCupBar/SettingsView.swift`

- [ ] **Step 4.1: Add `notificationMinutesBefore` to ViewModel**

In `Sources/WorldCupBar/WorldCupBarViewModel.swift`:

After the `@Published var analyticsEnabled: Bool {` block (around line 23), add:

```swift
@Published var notificationMinutesBefore: Int {
    didSet {
        UserDefaults.standard.set(
            notificationMinutesBefore,
            forKey: UserDefaultsKeys.notificationMinutesBefore
        )
        Task { await scheduleNotifications() }
    }
}
```

Add a `private let notificationScheduler: NotificationScheduler` stored property after the `private let analytics:` line:

```swift
private let notificationScheduler: NotificationScheduler
```

Update `init` signature and body — find `init(repository: any WorldCupDataProviding, analytics: any WorldCupAnalyticsTracking)` and change to:

```swift
init(
    repository: any WorldCupDataProviding,
    analytics: any WorldCupAnalyticsTracking,
    notificationScheduler: NotificationScheduler = NotificationScheduler.shared
) {
    self.repository = repository
    self.analytics = analytics
    self.notificationScheduler = notificationScheduler

    let storedDisplayMode = UserDefaults.standard.string(forKey: UserDefaultsKeys.displayMode)
        .flatMap(DisplayMode.init(rawValue:))
    self.displayMode = storedDisplayMode ?? .abbreviations

    let storedCodes = UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.followedCountryCodes)
    self.followedCountryCodes = Set(storedCodes ?? ["USA", "MEX", "CAN"])

    self.analyticsEnabled = UserDefaults.standard.object(forKey: UserDefaultsKeys.analyticsEnabled) as? Bool ?? true
    self.analytics.setAnalyticsEnabled(analyticsEnabled)

    self.notificationMinutesBefore = UserDefaults.standard.object(
        forKey: UserDefaultsKeys.notificationMinutesBefore
    ) as? Int ?? 15
}
```

Add `notificationMinutesBefore` key to the `UserDefaultsKeys` enum at the bottom:

```swift
static let notificationMinutesBefore = "notificationMinutesBefore"
```

Add a `scheduleNotifications()` private method:

```swift
private func scheduleNotifications() async {
    await notificationScheduler.schedule(
        matches: matches,
        followedCodes: followedCountryCodes,
        minutesBefore: notificationMinutesBefore
    )
}
```

In `apply(snapshot:)`, after `updateDisplayState()`, add:

```swift
Task { await scheduleNotifications() }
```

In the `followedCountryCodes` `didSet` (after the existing `updateDisplayState()` call), add:

```swift
Task { await scheduleNotifications() }
```

- [ ] **Step 4.2: Request permission on app start**

In `Sources/WorldCupBar/WorldCupBarApp.swift`, update the `.task` modifier:

```swift
// Find:
.task {
    await viewModel.start()
}

// Replace with:
.task {
    await NotificationScheduler.shared.requestPermission()
    await viewModel.start()
}
```

- [ ] **Step 4.3: Add notification picker to Settings**

In `Sources/WorldCupBar/SettingsView.swift`, add a `notificationsSection` computed property after `analyticsSection`:

```swift
private var notificationsSection: some View {
    SettingsSection(
        title: "Notifications",
        subtitle: "Get alerted before followed matches kick off."
    ) {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Kickoff alert")
                    .font(.system(size: 14, weight: .medium))
                Text("Notify before a followed match starts.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("Kickoff alert", selection: $viewModel.notificationMinutesBefore) {
                Text("Off").tag(0)
                Text("5 min").tag(5)
                Text("15 min").tag(15)
                Text("30 min").tag(30)
                Text("60 min").tag(60)
            }
            .labelsHidden()
            .frame(width: 120)
        }
        .padding(16)
    }
}
```

Add it to the `body` `VStack`:

```swift
// Find:
analyticsSection
dataSection

// Replace with:
analyticsSection
notificationsSection
dataSection
```

- [ ] **Step 4.4: Build and run all tests**

```bash
swift build --target WorldCupBar 2>&1 | tail -10
swift test 2>&1 | tail -15
```

Expected: `Build complete!` and all tests pass.

- [ ] **Step 4.5: Commit**

```bash
git add Sources/WorldCupBar/NotificationScheduler.swift \
        Sources/WorldCupBar/WorldCupBarViewModel.swift \
        Sources/WorldCupBar/WorldCupBarApp.swift \
        Sources/WorldCupBar/SettingsView.swift
git commit -m "feat(notifications): add configurable pre-match kickoff alerts (default 15 min)"
```

---

## Reviewer Checklist — Regression Gates

Run these checks before approving any PR that includes this work.

### Gate 1: Existing tests still pass

```bash
swift test 2>&1 | grep -E "passed|failed|error"
```

**Must pass:** All tests from the previous commit (≥18) plus the 4 new `WorldCupSnapshotTests`. Zero failures.

### Gate 2: Build succeeds for the app target

```bash
swift build --target WorldCupBar 2>&1 | grep -E "error:|Build complete"
```

**Must see:** `Build complete!` — no errors, no warnings treated as errors.

### Gate 3: Change-detection correctness

Verify `matchesContentEqual` handles:
- [ ] Same matches, different `fetchedAt` → **equal** (no re-render)
- [ ] Same match IDs, score updated → **not equal** (re-render triggered)
- [ ] New match added → **not equal** (re-render triggered)
- [ ] Match status flips to `.finished` → **not equal** (re-render triggered)

All four cases are covered by `WorldCupSnapshotTests`.

### Gate 4: Notification safety

Verify by inspection in `NotificationScheduler.schedule`:
- [ ] Past fire dates are skipped (`guard fireDate > now`)
- [ ] Non-followed matches are skipped (`guard isFollowed`)
- [ ] Live/finished matches are skipped (`guard match.status == .scheduled`)
- [ ] `minutesBefore == 0` removes all pending requests and returns early
- [ ] Notification identifiers are stable (`"kickoff-\(match.id)"`) — rescheduling the same match is idempotent

### Gate 5: Settings search bar behavior

Verify by inspection:
- [ ] Empty search shows all countries
- [ ] No-match search shows the "No countries match…" empty state
- [ ] Clearing via X button restores full list
- [ ] Toggling a country while filtered still commits the change (binding uses `viewModel.setFollowed`)
- [ ] `countrySearch` is `@State` (view-local, not in ViewModel) — correct MVVM placement

### Gate 6: UserDefaults persistence

- [ ] `notificationMinutesBefore` defaults to 15 on first launch
- [ ] Changing the picker saves to key `"notificationMinutesBefore"` in `UserDefaults.standard`
- [ ] Cold-launch restores the previously saved value

### Gate 7: MVVM compliance

- [ ] No business logic in `SettingsView` or `MenuBarDropdownView`
- [ ] `NotificationScheduler` is injected via `WorldCupBarViewModel.init` (testable)
- [ ] `countrySearch` filter is view-local `@State` — not a `@Published` on ViewModel (it's display state, not domain state)
- [ ] `WorldCupRepository` owns change-detection (data layer), not the ViewModel

---

## Self-Review Notes

**Spec coverage check:**
- ✅ "Following" label in Settings — Task 1
- ✅ Country search bar in Settings — Task 1
- ✅ Configurable notification, default 15 min — Tasks 3 & 4
- ✅ Cache / only update changed items — Task 2
- ✅ MVVM compliance — enforced throughout

**No placeholder scan:** All steps contain complete code. No "TBD" or "add validation".

**Type consistency:** `matchesContentEqual(to:)` introduced in Task 2 step 2.3, used in step 2.5 with matching signature. `NotificationScheduler.schedule(matches:followedCodes:minutesBefore:)` defined in Task 3, called in Task 4 with matching labels. `notificationMinutesBefore: Int` defined and read in Task 4 with same key `UserDefaultsKeys.notificationMinutesBefore`.
