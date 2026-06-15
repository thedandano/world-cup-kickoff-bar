import Foundation

public protocol WorldCupDataProviding: Sendable {
    func loadCachedSnapshot() throws -> WorldCupSnapshot?
    func refreshSnapshot() async throws -> WorldCupSnapshot
}

public struct WorldCupRepository: WorldCupDataProviding, Sendable {
    private let dataSource: any WorldCupDataSource
    private let mapper: WorldCup26Mapper
    private let store: WorldCupSnapshotStore
    private let retryPolicy: RetryPolicy
    private let now: @Sendable () -> Date

    public init(
        dataSource: any WorldCupDataSource,
        mapper: WorldCup26Mapper,
        store: WorldCupSnapshotStore,
        retryPolicy: RetryPolicy = RetryPolicy(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.dataSource = dataSource
        self.mapper = mapper
        self.store = store
        self.retryPolicy = retryPolicy
        self.now = now
    }

    public func loadCachedSnapshot() throws -> WorldCupSnapshot? {
        try store.load()
    }

    public func refreshSnapshot() async throws -> WorldCupSnapshot {
        let result = try await retryPolicy.execute(
            operation: fetchAndMapSnapshot,
            shouldRetry: shouldRetry(error:)
        )
        let cached = try? store.load()
        if let cached, cached.matchesContentEqual(to: result.value) {
            return cached
        }
        try store.save(result.value)
        return result.value
    }

    private func fetchAndMapSnapshot() async throws -> WorldCupSnapshot {
        async let games = dataSource.fetchGames()
        async let teams = dataSource.fetchTeams()
        async let stadiums = (try? dataSource.fetchStadiums()) ?? WorldCup26StadiumsResponse(stadiums: [])
        return try await mapper.mapSnapshot(
            gamesResponse: games,
            teamsResponse: teams,
            stadiumsResponse: stadiums,
            fetchedAt: now()
        )
    }

    private func shouldRetry(error: Error) -> RetryDirective {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotFindHost, .cannotConnectToHost,
                 .networkConnectionLost, .notConnectedToInternet, .dnsLookupFailed:
                return .retry
            default:
                return .noRetry
            }
        }

        if let dataError = error as? WorldCupDataError,
           case .httpStatus(let code, let retryAfter) = dataError {
            if code == 429 {
                return RetryDirective(shouldRetry: true, overrideDelay: retryAfter)
            }
            if 500..<600 ~= code {
                return .retry
            }
        }

        return .noRetry
    }

}
