import Foundation
import Testing
@testable import WorldCupBarCore

// MARK: - Fake data source

private struct FakeWorldCupDataSource: WorldCupDataSource {
    let gamesResponse: WorldCup26GamesResponse
    let teamsResponse: WorldCup26TeamsResponse
    let stadiumsResponse: WorldCup26StadiumsResponse
    let error: URLError?

    init(
        gamesResponse: WorldCup26GamesResponse = .fixture(),
        teamsResponse: WorldCup26TeamsResponse = .fixture(),
        stadiumsResponse: WorldCup26StadiumsResponse = WorldCup26StadiumsResponse(stadiums: []),
        error: URLError? = nil
    ) {
        self.gamesResponse = gamesResponse
        self.teamsResponse = teamsResponse
        self.stadiumsResponse = stadiumsResponse
        self.error = error
    }

    func fetchGames() async throws -> WorldCup26GamesResponse {
        if let error { throw error }
        return gamesResponse
    }

    func fetchTeams() async throws -> WorldCup26TeamsResponse {
        if let error { throw error }
        return teamsResponse
    }

    func fetchStadiums() async throws -> WorldCup26StadiumsResponse {
        if let error { throw error }
        return stadiumsResponse
    }
}

// MARK: - DTO fixtures

private extension WorldCup26GamesResponse {
    /// A minimal valid response with one finished match (score 1-0).
    static func fixture(homeScore: String = "1", awayScore: String = "0") -> WorldCup26GamesResponse {
        WorldCup26GamesResponse(games: [
            WorldCup26GameDTO(
                id: "1",
                homeTeamID: "13",
                awayTeamID: "14",
                homeScore: homeScore,
                awayScore: awayScore,
                localDate: "06/12/2026 18:00",
                finished: "TRUE",
                timeElapsed: "finished",
                stadiumID: "1"
            )
        ])
    }
}

private extension WorldCup26TeamsResponse {
    static func fixture() -> WorldCup26TeamsResponse {
        WorldCup26TeamsResponse(teams: [
            WorldCup26TeamDTO(id: "13", nameEn: "United States", fifaCode: "USA", iso2: "US"),
            WorldCup26TeamDTO(id: "14", nameEn: "Paraguay", fifaCode: "PAR", iso2: "PY")
        ])
    }
}

// MARK: - Helpers

private final class CallCounter: @unchecked Sendable {
    var value = 0
}

private func uniqueTempFileURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("WorldCupRepositoryTests-\(UUID().uuidString).json")
}

private func makeRepository(
    dataSource: FakeWorldCupDataSource,
    fileURL: URL,
    retryPolicy: RetryPolicy = RetryPolicy(maxAttempts: 1, sleep: { _ in }),
    now: @escaping @Sendable () -> Date = Date.init
) -> WorldCupRepository {
    WorldCupRepository(
        dataSource: dataSource,
        mapper: WorldCup26Mapper(
            fallbackTimeZone: TimeZone(secondsFromGMT: 0)!,
            locale: Locale(identifier: "en_US_POSIX")
        ),
        store: WorldCupSnapshotStore(fileURL: fileURL),
        retryPolicy: retryPolicy,
        now: now
    )
}

// MARK: - Tests

@Test func repositoryChangeDetectionReturnsCachedSnapshotWhenContentUnchanged() async throws {
    let fileURL = uniqueTempFileURL()
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let firstDate = Date(timeIntervalSince1970: 1_800_000_000)
    let secondDate = Date(timeIntervalSince1970: 1_800_001_000)
    let counter = CallCounter()
    let clock: @Sendable () -> Date = {
        counter.value += 1
        return counter.value == 1 ? firstDate : secondDate
    }

    let dataSource = FakeWorldCupDataSource()
    let repository = makeRepository(dataSource: dataSource, fileURL: fileURL, now: clock)

    let first = try await repository.refreshSnapshot(trigger: .manual)
    #expect(first.fetchedAt == firstDate)

    let second = try await repository.refreshSnapshot(trigger: .manual)
    // Same DTOs → matchesContentEqual short-circuits → returns cached snapshot1
    #expect(second.fetchedAt == firstDate, "Expected cached fetchedAt firstDate but got \(second.fetchedAt)")
}

@Test func repositoryChangedContentSavesAndReturnsNewSnapshot() async throws {
    let fileURL = uniqueTempFileURL()
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let firstFetchDate = Date(timeIntervalSince1970: 1_800_000_000)
    let secondFetchDate = Date(timeIntervalSince1970: 1_800_001_000)

    // First refresh: score 1-0
    let repo1 = makeRepository(
        dataSource: FakeWorldCupDataSource(gamesResponse: .fixture(homeScore: "1", awayScore: "0")),
        fileURL: fileURL,
        now: { firstFetchDate }
    )
    let snapshot1 = try await repo1.refreshSnapshot(trigger: .manual)
    #expect(snapshot1.matches[0].score == MatchScore(home: 1, away: 0))

    // Second refresh with a different score: 2-0
    let repo2 = makeRepository(
        dataSource: FakeWorldCupDataSource(gamesResponse: .fixture(homeScore: "2", awayScore: "0")),
        fileURL: fileURL,
        now: { secondFetchDate }
    )
    let snapshot2 = try await repo2.refreshSnapshot(trigger: .manual)
    #expect(snapshot2.matches[0].score == MatchScore(home: 2, away: 0))
    #expect(snapshot2.fetchedAt == secondFetchDate)
    #expect(snapshot2 != snapshot1)
}

@Test func repositoryErrorPropagatesAfterRetries() async throws {
    let fileURL = uniqueTempFileURL()
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let dataSource = FakeWorldCupDataSource(error: URLError(.timedOut))
    let retryPolicy = RetryPolicy(maxAttempts: 2, sleep: { _ in })
    let repository = makeRepository(dataSource: dataSource, fileURL: fileURL, retryPolicy: retryPolicy)

    await #expect(throws: URLError.self) {
        _ = try await repository.refreshSnapshot(trigger: .manual)
    }
}

@Test func repositoryLoadCachedSnapshotPassthrough() async throws {
    let fileURL = uniqueTempFileURL()
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let repository = makeRepository(
        dataSource: FakeWorldCupDataSource(),
        fileURL: fileURL,
        now: { Date(timeIntervalSince1970: 1_800_000_000) }
    )

    // Empty store → returns nil
    let beforeRefresh = try repository.loadCachedSnapshot()
    #expect(beforeRefresh == nil)

    // After a successful refresh, the store is populated
    _ = try await repository.refreshSnapshot(trigger: .manual)

    let afterRefresh = try repository.loadCachedSnapshot()
    #expect(afterRefresh != nil)
}
