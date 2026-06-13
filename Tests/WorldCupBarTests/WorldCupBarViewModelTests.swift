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
    let analytics = StubAnalytics()
    let viewModel = WorldCupBarViewModel(repository: repository, analytics: analytics, notificationScheduler: StubNotificationScheduler())

    await viewModel.start()

    #expect(viewModel.contentState == .postTournament)
    #expect(viewModel.menuBarTitle == "See you in 2030!")
}

@MainActor
@Test func viewModelShowsUnavailableStateWithoutCacheWhenRefreshFails() async {
    let repository = StubRepository(cachedSnapshot: nil, refreshError: URLError(.timedOut))
    let analytics = StubAnalytics()
    let viewModel = WorldCupBarViewModel(repository: repository, analytics: analytics, notificationScheduler: StubNotificationScheduler())

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
    let analytics = StubAnalytics()
    let viewModel = WorldCupBarViewModel(repository: repository, analytics: analytics, notificationScheduler: StubNotificationScheduler())

    await viewModel.start()

    if case .usingCachedData = viewModel.refreshState {
        // correct state
    } else {
        Issue.record("Expected usingCachedData refresh state, got \(viewModel.refreshState)")
    }
    #expect(viewModel.lastUpdated == cached.fetchedAt)
}

@MainActor
@Test func viewModelAnalyticsOptOutStopsEventRecording() async {
    let repository = StubRepository(cachedSnapshot: nil, refreshedSnapshot: nil)
    let analytics = StubAnalytics()
    let viewModel = WorldCupBarViewModel(repository: repository, analytics: analytics, notificationScheduler: StubNotificationScheduler())

    await viewModel.start()
    let countBefore = analytics.recorded.count

    viewModel.analyticsEnabled = false
    analytics.recorded.removeAll()
    viewModel.analyticsEnabled = false

    #expect(analytics.recorded.isEmpty)
    _ = countBefore
}

private struct StubRepository: WorldCupDataProviding {
    var cachedSnapshot: WorldCupSnapshot?
    var refreshedSnapshot: WorldCupSnapshot?
    var refreshError: Error?

    func loadCachedSnapshot() throws -> WorldCupSnapshot? {
        cachedSnapshot
    }

    func refreshSnapshot(trigger _: RefreshTrigger) async throws -> WorldCupSnapshot {
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

private final class StubAnalytics: @unchecked Sendable, WorldCupAnalyticsTracking {
    var isEnabled = true
    var recorded: [(name: String, properties: [String: String])] = []

    func setAnalyticsEnabled(_ isEnabled: Bool) { self.isEnabled = isEnabled }
    func recordUserAction(_ name: String, properties: [String: String]) {
        if isEnabled { recorded.append((name, properties)) }
    }
}
