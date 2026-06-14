# Menu-Bar Dropdown Match Tabs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the dropdown's standalone "Following" chips section and "Upcoming" list with a two-tab match list — **Following** (upcoming matches involving followed teams, default) and **All Matches** (the complete upcoming list, unfiltered).

**Architecture:** Add one derived property to `WorldCupBarViewModel` (`followedUpcomingMatches`) and rework `MenuBarDropdownView` to switch a single list between that property and the existing `upcomingMatches` via a segmented control. No Core/domain changes — `upcomingMatches` already returns the complete scheduled list.

**Tech Stack:** SwiftUI (macOS 13+), Swift Testing (`@Test`/`#expect`), SwiftPM.

---

## Design Decisions (review before implementing)

1. **Tab names:** `Following` (default) and **`All Matches`** (the complete upcoming list, including followed teams — *not* filtered). `All Matches` is the chosen replacement for the user's placeholder "All Others"; alternatives if preferred: `All Fixtures` (soccer-flavored) or `Everyone`. Changing it later is a one-line edit in `MatchListTab.title`.
2. **"Tab view" = segmented `Picker`**, not a SwiftUI `TabView`. A `TabView` adds page/tab-bar chrome that is wrong for a compact menu-bar popover; a segmented control at the top of the section is the idiomatic macOS pattern and visually "supersedes" the old "Upcoming" header.
3. **Following tab data source:** new `viewModel.followedUpcomingMatches` = `upcomingMatches` filtered to matches where the home or away team's code is in `followedCountryCodes`. When the user follows no teams, this is **empty** (we do *not* fall back to "all", unlike `MatchSelectionService.followedMatches`).
4. **All Matches tab data source:** the existing `viewModel.upcomingMatches` (all `.scheduled` matches, sorted by kickoff). Left unchanged.
5. **Row cap:** keep the current `.prefix(5)` for both tabs to keep the popover compact.
6. **Kept as-is:** toolbar (refresh/gear), the highlighted hero match section, footer, and the `WCBVibrancyBackground` window background.
7. **Removed:** `followedCountriesSection` and the `CountryChip` view (followed teams are now implied by the Following tab). `SectionHeader` and `FlowLayout` become unused and are deleted too (verified by grep in Task 3).

---

## File Structure

- **Modify** `Sources/WorldCupBar/WorldCupBarViewModel.swift` — add `followedUpcomingMatches` computed property (one responsibility: derive the followed-team subset of upcoming matches).
- **Modify** `Tests/WorldCupBarTests/WorldCupBarViewModelTests.swift` — unit tests for the new property.
- **Modify** `Sources/WorldCupBar/MenuBarDropdownView.swift` — swap the two old sections for one `matchesSection` driven by a `MatchListTab` segmented control.
- **Delete** `Sources/WorldCupBar/FlowLayout.swift` — orphaned once the chips section is gone (Task 3, grep-gated).

---

## Task 1: ViewModel — `followedUpcomingMatches` (TDD)

**Files:**
- Modify: `Sources/WorldCupBar/WorldCupBarViewModel.swift` (add computed property near `upcomingMatches`, ~line 81-85)
- Test: `Tests/WorldCupBarTests/WorldCupBarViewModelTests.swift`

- [ ] **Step 1: Write the failing tests**

Append these two tests to `Tests/WorldCupBarTests/WorldCupBarViewModelTests.swift` (after the last `@Test` function, before the `private struct StubRepository` declaration). They reuse the existing `StubRepository`/`StubAnalytics`/`StubNotificationScheduler` and `Country` statics already used in this file.

```swift
@MainActor
@Test func followedUpcomingMatchesContainsOnlyMatchesWithFollowedTeams() async {
    let future = Date(timeIntervalSince1970: 1_900_000_000)
    let snapshot = WorldCupSnapshot(
        matches: [
            WorldCupMatch(id: "m1", home: .unitedStates, away: .brazil,
                          kickoffDate: future, status: .scheduled, score: nil, venue: "MetLife Stadium"),
            WorldCupMatch(id: "m2", home: .argentina, away: .france,
                          kickoffDate: future.addingTimeInterval(3600), status: .scheduled, score: nil, venue: "SoFi Stadium"),
            WorldCupMatch(id: "m3", home: .germany, away: .japan,
                          kickoffDate: future.addingTimeInterval(7200), status: .scheduled, score: nil, venue: "Lumen Field")
        ],
        countries: Country.previewDefaults,
        fetchedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
    let viewModel = WorldCupBarViewModel(
        repository: StubRepository(cachedSnapshot: nil, refreshedSnapshot: snapshot),
        analytics: StubAnalytics(),
        notificationScheduler: StubNotificationScheduler()
    )

    await viewModel.start()
    viewModel.followedCountryCodes = ["USA"]

    #expect(viewModel.upcomingMatches.count == 3)
    #expect(viewModel.followedUpcomingMatches.map(\.id) == ["m1"])
}

@MainActor
@Test func followedUpcomingMatchesIsEmptyWhenNoTeamsFollowed() async {
    let future = Date(timeIntervalSince1970: 1_900_000_000)
    let snapshot = WorldCupSnapshot(
        matches: [
            WorldCupMatch(id: "m1", home: .unitedStates, away: .brazil,
                          kickoffDate: future, status: .scheduled, score: nil, venue: "MetLife Stadium")
        ],
        countries: Country.previewDefaults,
        fetchedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
    let viewModel = WorldCupBarViewModel(
        repository: StubRepository(cachedSnapshot: nil, refreshedSnapshot: snapshot),
        analytics: StubAnalytics(),
        notificationScheduler: StubNotificationScheduler()
    )

    await viewModel.start()
    viewModel.followedCountryCodes = []

    #expect(viewModel.upcomingMatches.count == 1)
    #expect(viewModel.followedUpcomingMatches.isEmpty)
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `swift test --filter followedUpcomingMatches`
Expected: FAIL — does not compile: "value of type 'WorldCupBarViewModel' has no member 'followedUpcomingMatches'".

- [ ] **Step 3: Add the property**

In `Sources/WorldCupBar/WorldCupBarViewModel.swift`, immediately after the existing `upcomingMatches` computed property (the block ending at line ~85), add:

```swift
    var followedUpcomingMatches: [WorldCupMatch] {
        upcomingMatches.filter { match in
            followedCountryCodes.contains(match.home.code)
                || followedCountryCodes.contains(match.away.code)
        }
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `swift test --filter followedUpcomingMatches`
Expected: PASS (2 tests).

- [ ] **Step 5: Run the full suite (no regressions)**

Run: `swift test`
Expected: PASS (30 tests — the prior 28 plus the 2 new).

- [ ] **Step 6: Commit**

```bash
git add Sources/WorldCupBar/WorldCupBarViewModel.swift Tests/WorldCupBarTests/WorldCupBarViewModelTests.swift
git commit -m "feat(menu): derive followedUpcomingMatches on the view model

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Dropdown — two-tab match list

**Files:**
- Modify: `Sources/WorldCupBar/MenuBarDropdownView.swift`

This task replaces two sections with one and adds the tab enum + state. No unit test (SwiftUI view); verified by build + manual check.

- [ ] **Step 1: Add the tab state property**

In `struct MenuBarDropdownView`, just below the existing stored properties (after `@Bindable var viewModel: WorldCupBarViewModel`, ~line 7), add:

```swift
    @State private var selectedTab: MatchListTab = .following
```

- [ ] **Step 2: Replace the body's section list**

Replace the current `body` (the `VStack` listing `toolbarSection`, `highlightedMatchSection`, `upcomingMatchesSection`, the `if … followedCountriesSection` block, and `footerSection`) with:

```swift
    var body: some View {
        VStack(alignment: .leading, spacing: WCBSpacing.md) {
            toolbarSection
            highlightedMatchSection
            matchesSection
            footerSection
        }
        .padding(.horizontal, WCBSpacing.md)
        .padding(.vertical, 14)
        .background(WCBVibrancyBackground().ignoresSafeArea())
    }
```

- [ ] **Step 3: Delete the two old sections**

Delete the entire `private var upcomingMatchesSection: some View { … }` computed property and the entire `private var followedCountriesSection: some View { … }` computed property.

- [ ] **Step 4: Add the new tabbed section + helpers**

Add these three members to `MenuBarDropdownView` (place where `upcomingMatchesSection` was):

```swift
    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: WCBSpacing.sm) {
            Picker("Match list", selection: $selectedTab) {
                ForEach(MatchListTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            matchList(for: selectedTab)
        }
    }

    @ViewBuilder
    private func matchList(for tab: MatchListTab) -> some View {
        let matches = tab == .following ? viewModel.followedUpcomingMatches : viewModel.upcomingMatches

        if matches.isEmpty {
            Text(emptyText(for: tab))
                .font(WCBFont.caption)
                .foregroundStyle(WCBColor.secondaryLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        } else {
            VStack(spacing: 0) {
                ForEach(matches.prefix(5)) { match in
                    MatchRow(
                        match: match,
                        title: viewModel.dropdownMatchupTitle(for: match),
                        time: viewModel.scheduledTime(for: match.kickoffDate)
                    )

                    if match.id != matches.prefix(5).last?.id {
                        Divider()
                            .overlay(WCBColor.separator)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(panelBackground)
        }
    }

    private func emptyText(for tab: MatchListTab) -> String {
        switch tab {
        case .following:
            return viewModel.followedCountryCodes.isEmpty
                ? "You're not following any teams. Add teams in Settings."
                : "No upcoming matches for the teams you follow."
        case .all:
            return upcomingEmptyStateText
        }
    }
```

- [ ] **Step 5: Add the `MatchListTab` enum**

Add at the bottom of the file, alongside the other `private struct` view helpers:

```swift
private enum MatchListTab: String, CaseIterable, Identifiable {
    case following
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .following: return "Following"
        case .all:       return "All Matches"
        }
    }
}
```

- [ ] **Step 6: Build**

Run: `swift build`
Expected: `Build complete!` (There will still be a reference to `CountryChip`/`SectionHeader`/`FlowLayout` definitions, but they are now unused — that's cleaned up in Task 3.)

- [ ] **Step 7: Manual verification**

Run the app, open the menu-bar dropdown, and confirm:
- The standalone "Following" chips section is gone.
- A segmented control reads **Following | All Matches**, defaulting to **Following**.
- **Following** lists only upcoming matches whose home or away team you follow.
- **All Matches** lists the complete upcoming set (followed teams included, none filtered out).
- With every team unfollowed (Settings), **Following** shows "You're not following any teams. Add teams in Settings."; **All Matches** still lists everything.

- [ ] **Step 8: Commit**

```bash
git add Sources/WorldCupBar/MenuBarDropdownView.swift
git commit -m "feat(menu): tab between Following and All Matches in the dropdown

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Remove orphaned view helpers

**Files:**
- Modify: `Sources/WorldCupBar/MenuBarDropdownView.swift` (delete `CountryChip`, `SectionHeader`)
- Delete: `Sources/WorldCupBar/FlowLayout.swift`

- [ ] **Step 1: Confirm the helpers are unused**

Run: `grep -rn "CountryChip\|SectionHeader\|FlowLayout" Sources/`
Expected: matches only on the *definitions* (no call-sites) — i.e. `CountryChip`/`SectionHeader` only inside `MenuBarDropdownView.swift` declarations and `FlowLayout` only in `FlowLayout.swift`. If any other call-site appears, stop and leave that helper in place.

- [ ] **Step 2: Delete the helpers**

- In `Sources/WorldCupBar/MenuBarDropdownView.swift`, delete the entire `private struct CountryChip: View { … }` and `private struct SectionHeader: View { … }` declarations.
- Delete the file `Sources/WorldCupBar/FlowLayout.swift`:

```bash
rm Sources/WorldCupBar/FlowLayout.swift
```

- [ ] **Step 3: Build and test**

Run: `swift build && swift test`
Expected: `Build complete!` and all 30 tests PASS.

- [ ] **Step 4: Lint the changed files**

Run: `swiftlint lint --strict Sources/WorldCupBar/MenuBarDropdownView.swift Sources/WorldCupBar/WorldCupBarViewModel.swift`
Expected: no *new* violations versus before this plan (pre-existing `closure_body_length` / `line_length` on long literals may remain; do not introduce new ones).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor(menu): drop now-unused CountryChip, SectionHeader, FlowLayout

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Optional follow-up (not required)

- `WorldCupBarViewModel.followedCountries` (the `[Country]` computed property, ~line 70) was only consumed by the removed chips section. If a project-wide grep (`grep -rn "\.followedCountries\b" Sources/`) shows no remaining references, it can be deleted in a separate small commit. Leave it if unsure — it is harmless and a reasonable part of the view model's surface.

---

## Self-Review

- **Spec coverage:** Remove Following section → Task 2 Step 3 + Task 3. Tab view superseding "Upcoming" → Task 2 (Steps 2, 4, 5). "Following" default showing followed teams' upcoming → Task 1 + `selectedTab = .following` (Task 2 Step 1) + `matchList` (Step 4). "All Matches" showing the complete unfiltered list → `matchList` uses `viewModel.upcomingMatches` (Step 4). Better name than "All Others" → Design Decision 1 ("All Matches"). ✓
- **Placeholders:** none — every step has exact code/commands.
- **Type consistency:** `MatchListTab` (cases `.following`/`.all`, `title`, `Identifiable.id`), `followedUpcomingMatches`, `upcomingMatches`, `MatchRow(match:title:time:)`, `panelBackground`, `upcomingEmptyStateText`, `WCBVibrancyBackground`, `WCBColor.secondaryLabel`/`.separator`, `WCBSpacing.sm`/`.md`, `WCBFont.caption` all match existing declarations confirmed in the source.
