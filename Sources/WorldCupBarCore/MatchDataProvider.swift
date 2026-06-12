public protocol MatchDataProvider: Sendable {
    func fetchMatches() async throws -> [WorldCupMatch]
}
