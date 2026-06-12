import Foundation

public protocol WorldCupDataProviding: Sendable {
    func loadCachedSnapshot() throws -> WorldCupSnapshot?
    func refreshSnapshot(trigger: RefreshTrigger) async throws -> WorldCupSnapshot
}

public struct WorldCupRepository: WorldCupDataProviding, Sendable {
    private let client: WorldCup26APIClient
    private let mapper: WorldCup26Mapper
    private let store: WorldCupSnapshotStore
    private let retryPolicy: RetryPolicy
    private let telemetry: any WorldCupTelemetry
    private let now: @Sendable () -> Date

    public init(
        client: WorldCup26APIClient,
        mapper: WorldCup26Mapper,
        store: WorldCupSnapshotStore,
        retryPolicy: RetryPolicy = RetryPolicy(),
        telemetry: any WorldCupTelemetry = NoOpWorldCupTelemetry(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.client = client
        self.mapper = mapper
        self.store = store
        self.retryPolicy = retryPolicy
        self.telemetry = telemetry
        self.now = now
    }

    public func loadCachedSnapshot() throws -> WorldCupSnapshot? {
        let snapshot = try store.load()
        if let snapshot {
            telemetry.recordCacheLoaded(matchCount: snapshot.matches.count, teamCount: snapshot.countries.count)
        }
        return snapshot
    }

    public func refreshSnapshot(trigger: RefreshTrigger) async throws -> WorldCupSnapshot {
        telemetry.recordRefreshStarted(trigger: trigger)
        let start = ContinuousClock.now
        let hasCache = (try? store.load()) != nil

        do {
            let result = try await retryPolicy.execute(
                operation: {
                    async let games = client.fetchGames()
                    async let teams = client.fetchTeams()
                    async let stadiums = (try? client.fetchStadiums()) ?? WorldCup26StadiumsResponse(stadiums: [])
                    return try await mapper.mapSnapshot(
                        gamesResponse: games,
                        teamsResponse: teams,
                        stadiumsResponse: stadiums,
                        fetchedAt: now()
                    )
                },
                shouldRetry: shouldRetry(error:)
            )
            let cached = try? store.load()
            if let cached, cached.matchesContentEqual(to: result.value) {
                telemetry.recordRefreshSucceeded(
                    snapshot: cached,
                    latency: start.duration(to: .now),
                    attemptCount: result.attemptCount
                )
                return cached
            }
            try store.save(result.value)
            telemetry.recordRefreshSucceeded(
                snapshot: result.value,
                latency: start.duration(to: .now),
                attemptCount: result.attemptCount
            )
            return result.value
        } catch {
            telemetry.recordRefreshFailed(
                error: error,
                latency: start.duration(to: .now),
                attemptCount: retryAttempts(from: error),
                hasCachedSnapshot: hasCache
            )
            throw error
        }
    }

    private func shouldRetry(error: Error) -> RetryDirective {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet, .dnsLookupFailed:
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

    private func retryAttempts(from error: Error) -> Int {
        if let dataError = error as? WorldCupDataError,
           case .httpStatus = dataError {
            return retryPolicy.maxAttempts
        }
        if error is URLError {
            return retryPolicy.maxAttempts
        }
        return 1
    }
}
