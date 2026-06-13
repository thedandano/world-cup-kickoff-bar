import Foundation

public struct MatchSelectionService: Sendable {
    public init() {}

    public func displayState(
        matches: [WorldCupMatch],
        followedCountryCodes: Set<String>,
        now: Date
    ) -> MatchDisplayState {
        let relevantMatches = followedMatches(from: matches, followedCountryCodes: followedCountryCodes)
        let liveMatches = relevantMatches
            .filter { $0.status.isLive }
            .sorted { liveSortKey(for: $0, now: now) < liveSortKey(for: $1, now: now) }

        if let mostUrgentLiveMatch = liveMatches.first {
            return .live(mostUrgentLiveMatch)
        }

        let upcomingFollowedMatch = relevantMatches
            .filter { $0.status == .scheduled && $0.kickoffDate >= now }
            .sorted { $0.kickoffDate < $1.kickoffDate }
            .first

        if let upcomingFollowedMatch {
            return .upcoming(upcomingFollowedMatch)
        }

        let nextTournamentMatch = matches
            .filter { $0.status == .scheduled && $0.kickoffDate >= now }
            .sorted { $0.kickoffDate < $1.kickoffDate }
            .first

        if let nextTournamentMatch {
            return .upcoming(nextTournamentMatch)
        }

        return .empty
    }

    public func followedMatches(
        from matches: [WorldCupMatch],
        followedCountryCodes: Set<String>
    ) -> [WorldCupMatch] {
        guard !followedCountryCodes.isEmpty else {
            return matches
        }

        return matches.filter { match in
            followedCountryCodes.contains(match.home.code) || followedCountryCodes.contains(match.away.code)
        }
    }

    public func isPostTournamentState(matches: [WorldCupMatch], now: Date) -> Bool {
        guard !matches.isEmpty else {
            return false
        }

        let hasFutureOrLiveMatch = matches.contains { match in
            match.status.isLive || (match.status == .scheduled && match.kickoffDate >= now)
        }

        guard !hasFutureOrLiveMatch else {
            return false
        }

        return matches.contains { $0.status == .finished }
    }

    private func liveSortKey(for match: WorldCupMatch, now: Date) -> Int {
        guard case .live(let minute) = match.status else {
            return Int.max
        }

        let expectedFullTimeMinute = 90
        return abs(expectedFullTimeMinute - (minute ?? 45))
    }
}
