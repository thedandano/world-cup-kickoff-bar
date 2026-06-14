public enum MatchDisplayState: Equatable, Sendable {
    case live(WorldCupMatch)
    case upcoming(WorldCupMatch)
    case empty

    public var match: WorldCupMatch? {
        switch self {
        case .live(let match), .upcoming(let match):
            match
        case .empty:
            nil
        }
    }
}
