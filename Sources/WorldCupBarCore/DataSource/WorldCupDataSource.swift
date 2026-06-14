import Foundation

/// Port for the upstream match-data API. Adapters perform the network fetch and
/// return the raw DTOs; `WorldCupRepository` owns mapping, retry, caching, and
/// change-detection.
///
/// Failure contract: to participate in the repository's retry + telemetry,
/// adapters MUST surface failures as `URLError` (transport) or
/// `WorldCupDataError.httpStatus(code:retryAfter:)` (HTTP). See
/// `WorldCupRepository.shouldRetry`.
public protocol WorldCupDataSource: Sendable {
    func fetchGames() async throws -> WorldCup26GamesResponse
    func fetchTeams() async throws -> WorldCup26TeamsResponse
    func fetchStadiums() async throws -> WorldCup26StadiumsResponse
}
