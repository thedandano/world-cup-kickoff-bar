import Foundation
import Testing
@testable import WorldCupBarCore

private func makeSnapshotFixtures() -> (games: WorldCup26GamesResponse, teams: WorldCup26TeamsResponse) {
    let games = WorldCup26GamesResponse(games: [
        WorldCup26GameDTO(
            id: "1",
            homeTeamID: "13",
            awayTeamID: "14",
            homeScore: "2",
            awayScore: "1",
            localDate: "06/12/2026 18:00",
            finished: "FALSE",
            timeElapsed: "67",
            stadiumID: "16"
        ),
        WorldCup26GameDTO(
            id: "2",
            homeTeamID: "5",
            awayTeamID: "6",
            homeScore: "0",
            awayScore: "0",
            localDate: "06/13/2026 15:00",
            finished: "FALSE",
            timeElapsed: "notstarted",
            stadiumID: "12"
        )
    ])
    let teams = WorldCup26TeamsResponse(teams: [
        WorldCup26TeamDTO(id: "13", nameEn: "United States", fifaCode: "USA", iso2: "US"),
        WorldCup26TeamDTO(id: "14", nameEn: "Paraguay", fifaCode: "PAR", iso2: "PY"),
        WorldCup26TeamDTO(id: "5", nameEn: "Canada", fifaCode: "CAN", iso2: "CA"),
        WorldCup26TeamDTO(id: "6", nameEn: "Bosnia and Herzegovina", fifaCode: "BIH", iso2: "BA")
    ])
    return (games, teams)
}

@Test func mapperBuildsSnapshotFromGamesAndTeamsResponses() throws {
    let mapper = WorldCup26Mapper(
        fallbackTimeZone: TimeZone(secondsFromGMT: 0)!,
        locale: Locale(identifier: "en_US_POSIX")
    )
    let fixtures = makeSnapshotFixtures()

    let snapshot = try mapper.mapSnapshot(
        gamesResponse: fixtures.games,
        teamsResponse: fixtures.teams,
        stadiumsResponse: WorldCup26StadiumsResponse(stadiums: []),
        fetchedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    #expect(snapshot.countries.count == 4)
    #expect(snapshot.matches.count == 2)
    #expect(snapshot.matches[0].status == .live(minute: 67))
    #expect(snapshot.matches[0].home.flagEmoji == "🇺🇸")
    #expect(snapshot.matches[1].status == .scheduled)
}

@Test func mapperPreservesUnknownLiveMinuteWithoutGuessing() throws {
    let mapper = WorldCup26Mapper(
        fallbackTimeZone: TimeZone(secondsFromGMT: 0)!,
        locale: Locale(identifier: "en_US_POSIX")
    )

    let match = try mapper.mapMatch(
        WorldCup26GameDTO(
            id: "4",
            homeTeamID: "13",
            awayTeamID: "14",
            homeScore: "3",
            awayScore: "0",
            localDate: "06/12/2026 18:00",
            finished: "FALSE",
            timeElapsed: "live",
            stadiumID: "16"
        ),
        countryByID: [
            "13": .unitedStates,
            "14": Country.from(code: "PAR", name: "Paraguay", isoCode: "PY")
        ]
    )

    #expect(match.status == .live(minute: nil))
}

// Regression: API returns "live" for in-progress matches without a minute.
// Mapper must preserve the live state without guessing a clock.
@Test func mapperRecognisesLiveStringAsLiveStatus() throws {
    let mapper = WorldCup26Mapper(
        fallbackTimeZone: TimeZone(secondsFromGMT: 0)!,
        locale: Locale(identifier: "en_US_POSIX")
    )

    let kickoffDate = Date.now.addingTimeInterval(-30 * 60)
    let dateString: String = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)!
        fmt.dateFormat = "MM/dd/yyyy HH:mm"
        return fmt.string(from: kickoffDate)
    }()

    let game = WorldCup26GameDTO(
        id: "99",
        homeTeamID: "13",
        awayTeamID: "14",
        homeScore: "2",
        awayScore: "0",
        localDate: dateString,
        finished: "FALSE",
        timeElapsed: "live",
        stadiumID: "1"
    )
    let countryByID: [String: Country] = [
        "13": Country.from(code: "USA", name: "United States", isoCode: "US"),
        "14": Country.from(code: "PAR", name: "Paraguay", isoCode: "PY")
    ]

    let match = try mapper.mapMatch(game, countryByID: countryByID)
    if case .live(let minute) = match.status {
        #expect(minute == nil)
    } else {
        Issue.record("Expected .live status but got \(match.status)")
    }
}

@Test func mapperThrowsForUnknownTeam() {
    let mapper = WorldCup26Mapper()
    let game = WorldCup26GameDTO(
        id: "1",
        homeTeamID: "missing",
        awayTeamID: "14",
        homeScore: "0",
        awayScore: "0",
        localDate: "06/12/2026 18:00",
        finished: "FALSE",
        timeElapsed: "notstarted",
        stadiumID: "16"
    )

    #expect(throws: WorldCupDataError.self) {
        try mapper.mapMatch(game, countryByID: [:])
    }
}

@Test func mapperSkipsTBDKnockoutGamesAndKeepsResolvedGames() throws {
    let mapper = WorldCup26Mapper(
        fallbackTimeZone: TimeZone(secondsFromGMT: 0)!,
        locale: Locale(identifier: "en_US_POSIX")
    )

    let teams = WorldCup26TeamsResponse(teams: [
        WorldCup26TeamDTO(id: "13", nameEn: "United States", fifaCode: "USA", iso2: "US"),
        WorldCup26TeamDTO(id: "14", nameEn: "Paraguay", fifaCode: "PAR", iso2: "PY")
    ])

    let games = WorldCup26GamesResponse(games: [
        WorldCup26GameDTO(
            id: "1",
            homeTeamID: "13",
            awayTeamID: "14",
            homeScore: "1",
            awayScore: "0",
            localDate: "06/12/2026 18:00",
            finished: "TRUE",
            timeElapsed: "finished",
            stadiumID: "1"
        ),
        WorldCup26GameDTO(
            id: "73",
            homeTeamID: "0",
            awayTeamID: "0",
            homeScore: "0",
            awayScore: "0",
            localDate: "06/28/2026 18:00",
            finished: "FALSE",
            timeElapsed: "notstarted",
            stadiumID: "2"
        )
    ])

    let snapshot = try mapper.mapSnapshot(
        gamesResponse: games,
        teamsResponse: teams,
        stadiumsResponse: WorldCup26StadiumsResponse(stadiums: []),
        fetchedAt: Date()
    )

    #expect(snapshot.matches.count == 1)
    #expect(snapshot.matches[0].id == "1")
}
