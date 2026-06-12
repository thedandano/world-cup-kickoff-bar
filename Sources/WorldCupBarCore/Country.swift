import Foundation

public struct Country: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let code: String
    public let name: String
    public let flagEmoji: String

    public var id: String { code }

    public init(code: String, name: String, flagEmoji: String) {
        self.code = code
        self.name = name
        self.flagEmoji = flagEmoji
    }
}

public extension Country {
    static let unitedStates = Country(code: "USA", name: "United States", flagEmoji: "🇺🇸")
    static let mexico = Country(code: "MEX", name: "Mexico", flagEmoji: "🇲🇽")
    static let canada = Country(code: "CAN", name: "Canada", flagEmoji: "🇨🇦")
    static let brazil = Country(code: "BRA", name: "Brazil", flagEmoji: "🇧🇷")
    static let argentina = Country(code: "ARG", name: "Argentina", flagEmoji: "🇦🇷")
    static let england = Country(code: "ENG", name: "England", flagEmoji: "🏴")
    static let france = Country(code: "FRA", name: "France", flagEmoji: "🇫🇷")
    static let germany = Country(code: "GER", name: "Germany", flagEmoji: "🇩🇪")
    static let japan = Country(code: "JPN", name: "Japan", flagEmoji: "🇯🇵")
    static let morocco = Country(code: "MAR", name: "Morocco", flagEmoji: "🇲🇦")

    static let worldCupDefaults: [Country] = [
        .unitedStates,
        .mexico,
        .canada,
        .brazil,
        .argentina,
        .england,
        .france,
        .germany,
        .japan,
        .morocco
    ]
}
