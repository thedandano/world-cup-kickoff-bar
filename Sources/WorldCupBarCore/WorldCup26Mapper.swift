import Foundation

public struct WorldCup26Mapper: Sendable {
    private let dateFormatter: DateFormatter
    private let fallbackTimeZone: TimeZone

    public init(fallbackTimeZone: TimeZone = .current, locale: Locale = Locale(identifier: "en_US_POSIX")) {
        self.fallbackTimeZone = fallbackTimeZone

        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.timeZone = fallbackTimeZone
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm"
        self.dateFormatter = dateFormatter
    }

    public func mapSnapshot(
        gamesResponse: WorldCup26GamesResponse,
        teamsResponse: WorldCup26TeamsResponse,
        stadiumsResponse: WorldCup26StadiumsResponse,
        fetchedAt: Date
    ) throws -> WorldCupSnapshot {
        let countries = teamsResponse.teams
            .map(mapCountry)
            .sorted { $0.name < $1.name }

        let countryByID = Dictionary(uniqueKeysWithValues: teamsResponse.teams.map { team in
            (team.id, mapCountry(team))
        })

        let cityByStadiumID = Dictionary(uniqueKeysWithValues: stadiumsResponse.stadiums.map { s in
            (s.id, s.cityEn)
        })

        let matches = try gamesResponse.games.compactMap { game -> WorldCupMatch? in
            do {
                return try mapMatch(game, countryByID: countryByID, cityByStadiumID: cityByStadiumID)
            } catch WorldCupDataError.unknownTeam {
                return nil
            }
        }
        .sorted { $0.kickoffDate < $1.kickoffDate }

        return WorldCupSnapshot(matches: matches, countries: countries, fetchedAt: fetchedAt)
    }

    public func mapCountry(_ team: WorldCup26TeamDTO) -> Country {
        Country.from(code: team.fifaCode, name: team.nameEn, isoCode: team.iso2)
    }

    public func mapMatch(
        _ game: WorldCup26GameDTO,
        countryByID: [String: Country],
        cityByStadiumID: [String: String] = [:]
    ) throws -> WorldCupMatch {
        guard let home = countryByID[game.homeTeamID] else {
            throw WorldCupDataError.unknownTeam(game.homeTeamID)
        }
        guard let away = countryByID[game.awayTeamID] else {
            throw WorldCupDataError.unknownTeam(game.awayTeamID)
        }
        guard let kickoffDate = dateFormatter.date(from: game.localDate) else {
            throw WorldCupDataError.invalidDate(game.localDate)
        }

        return WorldCupMatch(
            id: game.id,
            home: home,
            away: away,
            kickoffDate: kickoffDate,
            status: status(for: game, kickoffDate: kickoffDate),
            score: score(for: game),
            venue: cityByStadiumID[game.stadiumID] ?? game.stadiumID
        )
    }

    private func score(for game: WorldCup26GameDTO) -> MatchScore? {
        guard
            let homeScore = Int(game.homeScore),
            let awayScore = Int(game.awayScore)
        else {
            return nil
        }

        return MatchScore(home: homeScore, away: awayScore)
    }

    private func status(for game: WorldCup26GameDTO, kickoffDate: Date) -> MatchStatus {
        let elapsed = game.timeElapsed.lowercased()
        if elapsed == "finished" || game.finished == "TRUE" {
            return .finished
        }
        if elapsed == "notstarted" {
            return .scheduled
        }
        if let minute = Int(elapsed) {
            return .live(minute: minute)
        }
        // API returns "live" or "ht" without a specific minute — derive from kickoff.
        if elapsed == "live" || elapsed == "ht" {
            let elapsedMinutes = Int(Date.now.timeIntervalSince(kickoffDate) / 60)
            return .live(minute: max(1, min(elapsedMinutes, 120)))
        }
        return .scheduled
    }
}

public enum WorldCupDataError: Error, LocalizedError, Sendable {
    case invalidDate(String)
    case unknownTeam(String)
    case malformedResponse(String)
    case httpStatus(code: Int, retryAfter: Duration?)

    public var errorDescription: String? {
        switch self {
        case .invalidDate(let value):
            return "Could not parse match date \(value)."
        case .unknownTeam(let identifier):
            return "Missing team metadata for \(identifier)."
        case .malformedResponse(let message):
            return message
        case .httpStatus(let code, _):
            return "Unexpected HTTP status \(code)."
        }
    }
}

public struct WorldCup26GamesResponse: Codable, Sendable {
    public let games: [WorldCup26GameDTO]
}

public struct WorldCup26TeamsResponse: Codable, Sendable {
    public let teams: [WorldCup26TeamDTO]
}

public struct WorldCup26GameDTO: Codable, Sendable {
    public let id: String
    public let homeTeamID: String
    public let awayTeamID: String
    public let homeScore: String
    public let awayScore: String
    public let localDate: String
    public let finished: String
    public let timeElapsed: String
    public let stadiumID: String

    enum CodingKeys: String, CodingKey {
        case id
        case homeTeamID = "home_team_id"
        case awayTeamID = "away_team_id"
        case homeScore = "home_score"
        case awayScore = "away_score"
        case localDate = "local_date"
        case finished
        case timeElapsed = "time_elapsed"
        case stadiumID = "stadium_id"
    }
}

public struct WorldCup26TeamDTO: Codable, Sendable {
    public let id: String
    public let nameEn: String
    public let fifaCode: String
    public let iso2: String?

    enum CodingKeys: String, CodingKey {
        case id
        case nameEn = "name_en"
        case fifaCode = "fifa_code"
        case iso2
    }
}


public struct WorldCup26StadiumsResponse: Codable, Sendable {
    public let stadiums: [WorldCup26StadiumDTO]
}

public struct WorldCup26StadiumDTO: Codable, Sendable {
    public let id: String
    public let nameEn: String
    public let cityEn: String

    enum CodingKeys: String, CodingKey {
        case id
        case nameEn = "name_en"
        case cityEn = "city_en"
    }
}
