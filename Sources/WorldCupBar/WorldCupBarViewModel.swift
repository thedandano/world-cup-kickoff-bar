import Foundation
import SwiftUI
import WorldCupBarCore

@MainActor
final class WorldCupBarViewModel: ObservableObject {
    @Published var matches: [WorldCupMatch] = []
    @Published var displayState: MatchDisplayState = .empty
    @Published var displayMode: DisplayMode {
        didSet {
            UserDefaults.standard.set(displayMode.rawValue, forKey: UserDefaultsKeys.displayMode)
            updateDisplayState()
        }
    }
    @Published var followedCountryCodes: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(followedCountryCodes).sorted(), forKey: UserDefaultsKeys.followedCountryCodes)
            updateDisplayState()
        }
    }
    @Published var searchText = ""
    @Published var lastUpdated: Date?
    @Published var refreshErrorMessage: String?

    let availableCountries = Country.worldCupDefaults

    private let provider: MatchDataProvider
    private let selectionService = MatchSelectionService()
    private let formatter = MatchFormatter()

    var menuBarTitle: String {
        formatter.menuBarTitle(for: displayState, displayMode: displayMode)
    }

    var highlightedMatch: WorldCupMatch? {
        displayState.match
    }

    var followedCountries: [Country] {
        availableCountries.filter { followedCountryCodes.contains($0.code) }
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

    init(provider: MatchDataProvider) {
        self.provider = provider

        let storedDisplayMode = UserDefaults.standard.string(forKey: UserDefaultsKeys.displayMode)
            .flatMap(DisplayMode.init(rawValue:))
        self.displayMode = storedDisplayMode ?? .abbreviations

        let storedCodes = UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.followedCountryCodes)
        self.followedCountryCodes = Set(storedCodes ?? ["USA", "MEX", "CAN"])
    }

    func refresh() async {
        do {
            matches = try await provider.fetchMatches()
            lastUpdated = Date()
            refreshErrorMessage = nil
            updateDisplayState()
        } catch {
            refreshErrorMessage = "Could not refresh mock data."
            updateDisplayState()
        }
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

    func localTime(for date: Date) -> String {
        formatter.localTime(for: date)
    }

    func statusLine(for match: WorldCupMatch) -> String {
        formatter.statusLine(for: match)
    }

    private func updateDisplayState() {
        displayState = selectionService.displayState(
            matches: matches,
            followedCountryCodes: followedCountryCodes,
            now: Date()
        )
    }
}

private enum UserDefaultsKeys {
    static let displayMode = "displayMode"
    static let followedCountryCodes = "followedCountryCodes"
}
