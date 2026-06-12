import Foundation

public struct WorldCupSnapshot: Codable, Equatable, Sendable {
    public let matches: [WorldCupMatch]
    public let countries: [Country]
    public let fetchedAt: Date

    public init(matches: [WorldCupMatch], countries: [Country], fetchedAt: Date) {
        self.matches = matches
        self.countries = countries
        self.fetchedAt = fetchedAt
    }
}
