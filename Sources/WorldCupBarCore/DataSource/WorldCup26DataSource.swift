import Foundation

public struct WorldCup26DataSource: WorldCupDataSource, Sendable {
    public let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(baseURL: URL = URL(string: "https://worldcup26.ir")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    public func fetchGames() async throws -> WorldCup26GamesResponse {
        try await fetch(path: "get/games", as: WorldCup26GamesResponse.self)
    }

    public func fetchTeams() async throws -> WorldCup26TeamsResponse {
        try await fetch(path: "get/teams", as: WorldCup26TeamsResponse.self)
    }

    public func fetchStadiums() async throws -> WorldCup26StadiumsResponse {
        try await fetch(path: "get/stadiums", as: WorldCup26StadiumsResponse.self)
    }

    private func fetch<Response: Decodable>(path: String, as type: Response.Type) async throws -> Response {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WorldCupDataError.malformedResponse("The World Cup API did not return HTTP.")
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw WorldCupDataError.httpStatus(
                code: httpResponse.statusCode,
                retryAfter: retryAfter(from: httpResponse)
            )
        }

        return try decoder.decode(type, from: data)
    }

    private func retryAfter(from response: HTTPURLResponse) -> Duration? {
        guard let rawValue = response.value(forHTTPHeaderField: "Retry-After") else {
            return nil
        }
        guard let seconds = Double(rawValue) else {
            return nil
        }
        return .seconds(seconds)
    }
}
