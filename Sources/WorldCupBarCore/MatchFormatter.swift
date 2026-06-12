import Foundation

public struct MatchFormatter: Sendable {
    private let timeFormatter: DateFormatter

    public init(timeZone: TimeZone = .current, locale: Locale = .current) {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.timeZone = timeZone
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        self.timeFormatter = timeFormatter
    }

    public func menuBarTitle(for state: MatchDisplayState, displayMode: DisplayMode) -> String {
        guard let match = state.match else {
            return "World Cup"
        }

        switch state {
        case .live:
            return liveTitle(for: match, displayMode: displayMode)
        case .upcoming:
            return upcomingTitle(for: match, displayMode: displayMode)
        case .empty:
            return "World Cup"
        }
    }

    public func matchupTitle(for match: WorldCupMatch, displayMode: DisplayMode) -> String {
        switch displayMode {
        case .abbreviations:
            return "\(match.home.code)-\(match.away.code)"
        case .flags:
            return "\(match.home.flagEmoji) \(match.away.flagEmoji)"
        }
    }

    public func localTime(for date: Date) -> String {
        timeFormatter.string(from: date)
    }

    public func statusLine(for match: WorldCupMatch) -> String {
        switch match.status {
        case .scheduled:
            return localTime(for: match.kickoffDate)
        case .live(let minute):
            return "Live \(minute)'"
        case .finished:
            return "Final"
        }
    }

    private func upcomingTitle(for match: WorldCupMatch, displayMode: DisplayMode) -> String {
        "\(matchupTitle(for: match, displayMode: displayMode)) \(localTime(for: match.kickoffDate))"
    }

    private func liveTitle(for match: WorldCupMatch, displayMode: DisplayMode) -> String {
        guard let score = match.score else {
            return "\(matchupTitle(for: match, displayMode: displayMode)) Live"
        }

        switch displayMode {
        case .abbreviations:
            return "\(match.home.code) \(score.home)-\(score.away) \(match.away.code)"
        case .flags:
            return "\(match.home.flagEmoji) \(score.home)-\(score.away) \(match.away.flagEmoji)"
        }
    }
}
