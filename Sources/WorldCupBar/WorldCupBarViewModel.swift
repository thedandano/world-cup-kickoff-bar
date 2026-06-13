import Foundation
import SwiftUI
import WorldCupBarCore

@MainActor
@Observable
final class WorldCupBarViewModel {
    private(set) var matches: [WorldCupMatch] = []
    private(set) var displayState: MatchDisplayState = .empty
    private(set) var contentState: WorldCupContentState = .loading
    var displayMode: DisplayMode {
        didSet {
            UserDefaults.standard.set(displayMode.rawValue, forKey: UserDefaultsKeys.displayMode)
            analytics.recordUserAction("display_mode_changed", properties: ["mode": displayMode.rawValue])
        }
    }
    var followedCountryCodes: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(followedCountryCodes).sorted(), forKey: UserDefaultsKeys.followedCountryCodes)
            analytics.recordUserAction("followed_countries_changed", properties: ["count": "\(followedCountryCodes.count)"])
            updateDisplayState()
            Task { await scheduleNotifications() }
        }
    }
    var analyticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(analyticsEnabled, forKey: UserDefaultsKeys.analyticsEnabled)
            analytics.setAnalyticsEnabled(analyticsEnabled)
        }
    }
    var notificationMinutesBefore: Int {
        didSet {
            UserDefaults.standard.set(
                notificationMinutesBefore,
                forKey: UserDefaultsKeys.notificationMinutesBefore
            )
            Task { await scheduleNotifications() }
        }
    }
    var searchText = ""
    var lastUpdated: Date?
    private(set) var refreshState: RefreshState = .idle

    private(set) var availableCountries: [Country] = []
    private let repository: any WorldCupDataProviding
    private let selectionService = MatchSelectionService()
    private let formatter = MatchFormatter()
    private let analytics: any WorldCupAnalyticsTracking
    private let notificationScheduler: any NotificationScheduling
    private var pollingTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var hasStarted = false

    var menuBarTitle: String {
        switch contentState {
        case .loading:
            return "Loading..."
        case .unavailable:
            return "World Cup"
        case .postTournament:
            return "See you in 2030!"
        case .content:
            return formatter.menuBarTitle(for: displayState, displayMode: displayMode)
        }
    }

    var highlightedMatch: WorldCupMatch? {
        displayState.match
    }

    var followedCountries: [Country] {
        availableCountries.filter { followedCountryCodes.contains($0.code) }
    }

    var isRefreshing: Bool {
        if case .refreshing = refreshState {
            return true
        }
        return false
    }

    var upcomingMatches: [WorldCupMatch] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let futureMatches = matches
            .filter { $0.status == .scheduled }
            .sorted { $0.kickoffDate < $1.kickoffDate }

        guard !query.isEmpty else {
            return futureMatches
        }

        return futureMatches.filter { match in
            match.home.name.lowercased().contains(query)
                || match.away.name.lowercased().contains(query)
                || match.home.code.lowercased().contains(query)
                || match.away.code.lowercased().contains(query)
                || match.venue.lowercased().contains(query)
        }
    }

    var footerStatusText: String {
        switch refreshState {
        case .idle:
            guard let lastUpdated else {
                return "Live data"
            }
            return "Updated \(formatter.localTime(for: lastUpdated))"
        case .refreshing:
            return "Refreshing live data..."
        case .usingCachedData(let message), .failed(let message):
            return message
        }
    }

    init(
        repository: any WorldCupDataProviding,
        analytics: any WorldCupAnalyticsTracking,
        notificationScheduler: any NotificationScheduling = NotificationScheduler.shared
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
        self.notificationMinutesBefore = UserDefaults.standard.object(
            forKey: UserDefaultsKeys.notificationMinutesBefore
        ) as? Int ?? 15
        self.analytics.setAnalyticsEnabled(analyticsEnabled)
    }

    func start() async {
        guard !hasStarted else {
            return
        }

        hasStarted = true

        if let cachedSnapshot = try? repository.loadCachedSnapshot() {
            apply(snapshot: cachedSnapshot)
            refreshState = .usingCachedData("Using cached match data until live refresh completes.")
        }

        await refresh(trigger: .appLaunch)
        restartPolling()
    }

    func refresh() async {
        await refresh(trigger: .manual)
    }

    func refresh(trigger: RefreshTrigger) async {
        guard refreshTask == nil else {
            return
        }

        refreshState = .refreshing
        let task = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let snapshot = try await repository.refreshSnapshot(trigger: trigger)
                await MainActor.run {
                    self.apply(snapshot: snapshot)
                    self.refreshState = .idle
                    self.restartPolling()
                }
            } catch {
                await MainActor.run {
                    if self.lastUpdated != nil {
                        self.refreshState = .usingCachedData("Live refresh failed. Showing the last known snapshot.")
                    } else {
                        self.contentState = .unavailable
                        self.refreshState = .failed("Live data unavailable right now.")
                    }
                    self.restartPolling()
                }
            }

            await MainActor.run {
                self.refreshTask = nil
            }
        }
        refreshTask = task
        await task.value
    }

    func setFollowed(_ country: Country, isFollowed: Bool) {
        if isFollowed {
            followedCountryCodes.insert(country.code)
        } else {
            followedCountryCodes.remove(country.code)
        }
    }

    func matchupTitle(for match: WorldCupMatch) -> String {
        formatter.matchupTitle(for: match, displayMode: displayMode)
    }


    func dropdownMatchupTitle(for match: WorldCupMatch) -> String {
        formatter.dropdownMatchupTitle(for: match)
    }

    func localTime(for date: Date) -> String {
        formatter.localTime(for: date)
    }

    func scheduledTime(for date: Date) -> String {
        formatter.scheduledTime(for: date)
    }

    func statusLine(for match: WorldCupMatch) -> String {
        formatter.statusLine(for: match)
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func apply(snapshot: WorldCupSnapshot) {
        matches = snapshot.matches
        availableCountries = snapshot.countries
        lastUpdated = snapshot.fetchedAt
        updateDisplayState()
        Task { await scheduleNotifications() }
    }

    private func scheduleNotifications() async {
        await notificationScheduler.schedule(
            matches: matches,
            followedCodes: followedCountryCodes,
            minutesBefore: notificationMinutesBefore
        )
    }

    private func updateDisplayState() {
        if selectionService.isPostTournamentState(matches: matches, now: Date()) {
            contentState = .postTournament
            displayState = .empty
            return
        }

        displayState = selectionService.displayState(
            matches: matches,
            followedCountryCodes: followedCountryCodes,
            now: Date()
        )

        if matches.isEmpty, lastUpdated == nil {
            contentState = .loading
            return
        }

        contentState = .content(displayState)
    }

    private func restartPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                let delay = self.nextPollingInterval
                try? await Task.sleep(for: delay)
                await self.refresh(trigger: .automatic)
            }
        }
    }

    private var nextPollingInterval: Duration {
        switch contentState {
        case .content(.live):
            return .seconds(30)
        case .loading, .unavailable, .postTournament, .content:
            return .seconds(300)
        }
    }
}

private enum UserDefaultsKeys {
    static let displayMode = "displayMode"
    static let followedCountryCodes = "followedCountryCodes"
    static let analyticsEnabled = "analyticsEnabled"
    static let notificationMinutesBefore = "notificationMinutesBefore"
}

enum WorldCupContentState: Equatable {
    case loading
    case content(MatchDisplayState)
    case unavailable
    case postTournament
}

enum RefreshState: Equatable {
    case idle
    case refreshing
    case usingCachedData(String)
    case failed(String)
}
