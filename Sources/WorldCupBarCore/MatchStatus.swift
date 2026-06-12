public enum MatchStatus: Codable, Equatable, Sendable {
    case scheduled
    case live(minute: Int)
    case finished

    public var isLive: Bool {
        if case .live = self {
            return true
        }
        return false
    }
}
