import Foundation

public struct MockMatchDataProvider: MatchDataProvider {
    public init() {}

    public func fetchMatches() async throws -> [WorldCupMatch] {
        MockMatchDataProvider.sampleMatches(referenceDate: Date())
    }

    public static func sampleMatches(referenceDate: Date) -> [WorldCupMatch] {
        [
            WorldCupMatch(
                id: "usa-mex-live",
                home: .unitedStates,
                away: .mexico,
                kickoffDate: Calendar.current.date(byAdding: .minute, value: -67, to: referenceDate) ?? referenceDate,
                status: .live(minute: 67),
                score: MatchScore(home: 1, away: 0),
                venue: "Estadio Azteca"
            ),
            WorldCupMatch(
                id: "can-bra-upcoming",
                home: .canada,
                away: .brazil,
                kickoffDate: Calendar.current.date(byAdding: .hour, value: 3, to: referenceDate) ?? referenceDate,
                status: .scheduled,
                score: nil,
                venue: "BMO Field"
            ),
            WorldCupMatch(
                id: "arg-fra-upcoming",
                home: .argentina,
                away: .france,
                kickoffDate: Calendar.current.date(byAdding: .hour, value: 8, to: referenceDate) ?? referenceDate,
                status: .scheduled,
                score: nil,
                venue: "MetLife Stadium"
            ),
            WorldCupMatch(
                id: "jpn-mar-upcoming",
                home: .japan,
                away: .morocco,
                kickoffDate: Calendar.current.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate,
                status: .scheduled,
                score: nil,
                venue: "Lumen Field"
            ),
            WorldCupMatch(
                id: "eng-ger-finished",
                home: .england,
                away: .germany,
                kickoffDate: Calendar.current.date(byAdding: .hour, value: -8, to: referenceDate) ?? referenceDate,
                status: .finished,
                score: MatchScore(home: 2, away: 2),
                venue: "SoFi Stadium"
            )
        ]
    }
}
