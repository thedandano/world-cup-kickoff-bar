import Foundation

public struct WorldCupMatch: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let home: Country
    public let away: Country
    public let kickoffDate: Date
    public let status: MatchStatus
    public let score: MatchScore?
    public let venue: String

    public init(
        id: String,
        home: Country,
        away: Country,
        kickoffDate: Date,
        status: MatchStatus,
        score: MatchScore?,
        venue: String
    ) {
        self.id = id
        self.home = home
        self.away = away
        self.kickoffDate = kickoffDate
        self.status = status
        self.score = score
        self.venue = venue
    }

    public func includes(countryCode: String) -> Bool {
        home.code == countryCode || away.code == countryCode
    }
}
