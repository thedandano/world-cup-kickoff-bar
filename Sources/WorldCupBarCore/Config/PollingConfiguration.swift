import Foundation

/// All tunable values for `PollingIntervalPolicy`.
///
/// This is the single place to adjust how aggressively the app polls the
/// `worldcup26.ir` API. Change `default` to retune the shipped behavior.
public struct PollingConfiguration: Sendable {
    /// Refresh interval while any match is live.
    public let liveInterval: Duration
    /// Refresh interval once the soonest kickoff is inside the warm-up window.
    public let imminentInterval: Duration
    /// How long before kickoff to start polling at `imminentInterval`.
    public let warmupWindow: Duration
    /// Longest the app will ever wait between refreshes while idle.
    public let idleCap: Duration
    /// How long after a scheduled kickoff time a match is still treated as
    /// live-imminent. The API lags flipping a match to `.live`, so a match still
    /// flagged `.scheduled` with a recently-passed kickoff is presumably underway.
    /// Bounded so a permanently stuck scheduled match cannot pin polling forever.
    public let kickoffGraceWindow: Duration

    public init(
        liveInterval: Duration = .seconds(30),
        imminentInterval: Duration = .seconds(60),
        warmupWindow: Duration = .seconds(10 * 60),         // 10 min
        idleCap: Duration = .seconds(3 * 60 * 60),          // 3 h
        kickoffGraceWindow: Duration = .seconds(3 * 60 * 60) // 3 h
    ) {
        self.liveInterval = liveInterval
        self.imminentInterval = imminentInterval
        self.warmupWindow = warmupWindow
        self.idleCap = idleCap
        self.kickoffGraceWindow = kickoffGraceWindow
    }

    /// The values the app ships with.
    public static let `default` = PollingConfiguration()
}
