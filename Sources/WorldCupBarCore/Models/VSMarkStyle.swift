/// The drawn "vs" mark shown between two teams. Persisted as `rawValue`.
public enum VSMarkStyle: String, CaseIterable, Codable, Equatable, Sendable {
    case italic
    case ring
    case slash
    case clash

    public var displayName: String {
        switch self {
        case .italic: return "Italic"
        case .ring:   return "Ring"
        case .slash:  return "Slash"
        case .clash:  return "Clash"
        }
    }

    /// Plain-text separator for surfaces that can't render the drawn mark.
    /// The macOS menu-bar label is a single text string (it cannot host a
    /// composed view), so it uses this instead of the `VSMark` view.
    public var textSeparator: String {
        switch self {
        case .italic, .ring: return "vs"
        case .slash:         return "v/s"
        case .clash:         return "V/S"
        }
    }
}
