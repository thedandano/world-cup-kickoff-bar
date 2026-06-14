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

    public func matchesContentEqual(to other: WorldCupSnapshot) -> Bool {
        guard matches.count == other.matches.count else { return false }
        let byID = Dictionary(uniqueKeysWithValues: matches.map { ($0.id, $0) })
        return other.matches.allSatisfy { otherMatch in
            guard let cached = byID[otherMatch.id] else { return false }
            return cached.status == otherMatch.status && cached.score == otherMatch.score
        }
    }
}
