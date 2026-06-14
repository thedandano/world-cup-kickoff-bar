import Foundation

public struct Country: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let code: String
    public let name: String
    public let isoCode: String?
    public let flagEmoji: String

    public var id: String { code }

    public init(code: String, name: String, isoCode: String? = nil, flagEmoji: String) {
        self.code = code
        self.name = name
        self.isoCode = isoCode
        self.flagEmoji = flagEmoji
    }

    public var hasRenderableFlag: Bool {
        !flagEmoji.isEmpty
    }

    public static func from(code: String, name: String, isoCode: String?) -> Country {
        Country(
            code: code,
            name: name,
            isoCode: isoCode,
            flagEmoji: FlagEmojiBuilder.emoji(from: isoCode) ?? ""
        )
    }
}

public extension Country {
    static let unitedStates = Country.from(code: "USA", name: "United States", isoCode: "US")
    static let mexico = Country.from(code: "MEX", name: "Mexico", isoCode: "MX")
    static let canada = Country.from(code: "CAN", name: "Canada", isoCode: "CA")
    static let brazil = Country.from(code: "BRA", name: "Brazil", isoCode: "BR")
    static let argentina = Country.from(code: "ARG", name: "Argentina", isoCode: "AR")
    static let england = Country(code: "ENG", name: "England", isoCode: "GB", flagEmoji: "🏴")
    static let france = Country.from(code: "FRA", name: "France", isoCode: "FR")
    static let germany = Country.from(code: "GER", name: "Germany", isoCode: "DE")
    static let japan = Country.from(code: "JPN", name: "Japan", isoCode: "JP")
    static let morocco = Country.from(code: "MAR", name: "Morocco", isoCode: "MA")

    static let previewDefaults: [Country] = [
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

enum FlagEmojiBuilder {
    private static let subdivisionOverrides: [String: String] = [
        "ENG": "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
        "SCO": "🏴󠁧󠁢󠁳󠁣󠁴󠁿",
        "WAL": "🏴󠁧󠁢󠁷󠁬󠁳󠁿"
    ]

    static func emoji(from isoCode: String?) -> String? {
        guard let isoCode else { return nil }

        if let override = subdivisionOverrides[isoCode.uppercased()] {
            return override
        }

        guard isoCode.count == 2 else { return nil }

        let scalars = isoCode.uppercased().unicodeScalars.compactMap { scalar -> UnicodeScalar? in
            guard let base = UnicodeScalar(127397 + scalar.value) else {
                return nil
            }
            return base
        }

        guard scalars.count == 2 else { return nil }

        return String(String.UnicodeScalarView(scalars))
    }
}
