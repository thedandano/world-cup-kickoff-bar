import Foundation
import Testing
@testable import WorldCupBar
import WorldCupBarCore

@MainActor
@Test func viewModelUsesCachedSnapshotAndTransitionsToPostTournament() async {
    let snapshot = WorldCupSnapshot(
        matches: [
            WorldCupMatch(
                id: "final",
                home: .argentina,
                away: .france,
                kickoffDate: Date(timeIntervalSince1970: 1_799_900_000),
                status: .finished,
                score: MatchScore(home: 3, away: 2),
                venue: "MetLife Stadium"
            )
        ],
        countries: Country.previewDefaults,
        fetchedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
    let repository = StubRepository(cachedSnapshot: snapshot, refreshedSnapshot: snapshot)
    let viewModel = WorldCupBarViewModel(
        repository: repository,
        notificationScheduler: StubNotificationScheduler()
    )

    await viewModel.start()

    #expect(viewModel.contentState == .postTournament)
    #expect(viewModel.menuBarTitle == "See you in 2030!")
}

@MainActor
@Test func viewModelShowsUnavailableStateWithoutCacheWhenRefreshFails() async {
    let repository = StubRepository(cachedSnapshot: nil, refreshError: URLError(.timedOut))
    let viewModel = WorldCupBarViewModel(
        repository: repository,
        notificationScheduler: StubNotificationScheduler()
    )

    await viewModel.start()

    #expect(viewModel.contentState == .unavailable)
}

@MainActor
@Test func viewModelRetainsCachedDataWhenRefreshFails() async {
    let cached = WorldCupSnapshot(
        matches: [],
        countries: Country.previewDefaults,
        fetchedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
    let repository = StubRepository(cachedSnapshot: cached, refreshError: URLError(.timedOut))
    let viewModel = WorldCupBarViewModel(
        repository: repository,
        notificationScheduler: StubNotificationScheduler()
    )

    await viewModel.start()

    if case .usingCachedData = viewModel.refreshState {
        // correct state
    } else {
        Issue.record("Expected usingCachedData refresh state, got \(viewModel.refreshState)")
    }
    #expect(viewModel.lastUpdated == cached.fetchedAt)
}

@MainActor
@Test func followedUpcomingMatchesContainsOnlyMatchesWithFollowedTeams() async {
    let future = Date(timeIntervalSince1970: 1_900_000_000)
    let snapshot = WorldCupSnapshot(
        matches: [
            WorldCupMatch(id: "m1", home: .unitedStates, away: .brazil,
                          kickoffDate: future,
                          status: .scheduled, score: nil, venue: "MetLife Stadium"),
            WorldCupMatch(id: "m2", home: .argentina, away: .france,
                          kickoffDate: future.addingTimeInterval(3600),
                          status: .scheduled, score: nil, venue: "SoFi Stadium"),
            WorldCupMatch(id: "m3", home: .germany, away: .japan,
                          kickoffDate: future.addingTimeInterval(7200),
                          status: .scheduled, score: nil, venue: "Lumen Field")
        ],
        countries: Country.previewDefaults,
        fetchedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
    let viewModel = WorldCupBarViewModel(
        repository: StubRepository(cachedSnapshot: nil, refreshedSnapshot: snapshot),
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
        notificationScheduler: StubNotificationScheduler()
    )

    await viewModel.start()
    viewModel.followedCountryCodes = []

    #expect(viewModel.upcomingMatches.count == 1)
    #expect(viewModel.followedUpcomingMatches.isEmpty)
}

@MainActor
@Test func dropdownSpotlightScopesToTheSelectedTab() async {
    let soon = Date(timeIntervalSinceNow: 1_800)
    let later = Date(timeIntervalSinceNow: 3_600)
    let snapshot = WorldCupSnapshot(
        matches: [
            WorldCupMatch(id: "argfra", home: .argentina, away: .france,
                          kickoffDate: soon, status: .scheduled, score: nil, venue: "MetLife Stadium"),
            WorldCupMatch(id: "usabra", home: .unitedStates, away: .brazil,
                          kickoffDate: later, status: .scheduled, score: nil, venue: "SoFi Stadium")
        ],
        countries: Country.previewDefaults,
        fetchedAt: Date()
    )
    let viewModel = WorldCupBarViewModel(
        repository: StubRepository(cachedSnapshot: nil, refreshedSnapshot: snapshot),
        notificationScheduler: StubNotificationScheduler()
    )

    await viewModel.start()
    viewModel.followedCountryCodes = ["USA"]

    // All Matches → soonest overall (ARG vs FRA). Following → soonest followed (USA vs BRA).
    #expect(viewModel.dropdownSpotlight(followedOnly: false).match?.id == "argfra")
    #expect(viewModel.dropdownSpotlight(followedOnly: true).match?.id == "usabra")
}

@MainActor
@Test func vsMarkStyleDefaultsToRing() {
    let suite = "vsMarkTest-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    let viewModel = WorldCupBarViewModel(
        repository: StubRepository(cachedSnapshot: nil, refreshedSnapshot: nil),
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
        notificationScheduler: StubNotificationScheduler(),
        defaults: defaults
    )
    first.vsMarkStyle = .clash

    let second = WorldCupBarViewModel(
        repository: StubRepository(cachedSnapshot: nil, refreshedSnapshot: nil),
        notificationScheduler: StubNotificationScheduler(),
        defaults: defaults
    )

    #expect(second.vsMarkStyle == .clash)
}

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
        notificationScheduler: StubNotificationScheduler(),
        defaults: defaults
    )

    await viewModel.start()

    #expect(viewModel.menuBarLabel == .text("See you in 2030!"))
}

private struct StubRepository: WorldCupDataProviding {
    var cachedSnapshot: WorldCupSnapshot?
    var refreshedSnapshot: WorldCupSnapshot?
    var refreshError: Error?

    func loadCachedSnapshot() throws -> WorldCupSnapshot? {
        cachedSnapshot
    }

    func refreshSnapshot() async throws -> WorldCupSnapshot {
        if let refreshError {
            throw refreshError
        }
        return refreshedSnapshot ?? WorldCupSnapshot(matches: [], countries: [], fetchedAt: Date())
    }
}

@MainActor
private final class StubNotificationScheduler: NotificationScheduling {
    func requestPermission() async {}
    func schedule(matches _: [WorldCupMatch], followedCodes _: Set<String>, minutesBefore _: Int) async {}
    func cancelAll() {}
}
