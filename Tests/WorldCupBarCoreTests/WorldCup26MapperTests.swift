import Foundation
import Testing
@testable import WorldCupBarCore

@Test func mapperBuildsSnapshotFromGamesAndTeamsResponses() throws {
    let mapper = WorldCup26Mapper(
        fallbackTimeZone: TimeZone(secondsFromGMT: 0)!,
        locale: Locale(identifier: "en_US_POSIX")
    )

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

    let snapshot = try mapper.mapSnapshot(
        gamesResponse: games,
        teamsResponse: teams,
        stadiumsResponse: WorldCup26StadiumsResponse(stadiums: []),
        fetchedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )

    #expect(snapshot.countries.count == 4)
    #expect(snapshot.matches.count == 2)
    #expect(snapshot.matches[0].status == .live(minute: 67))
    #expect(snapshot.matches[0].home.flagEmoji == "🇺🇸")
    #expect(snapshot.matches[1].status == .scheduled)
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

    let snapshot = try mapper.mapSnapshot(gamesResponse: games, teamsResponse: teams, stadiumsResponse: WorldCup26StadiumsResponse(stadiums: []), fetchedAt: Date())

    #expect(snapshot.matches.count == 1)
    #expect(snapshot.matches[0].id == "1")
}
