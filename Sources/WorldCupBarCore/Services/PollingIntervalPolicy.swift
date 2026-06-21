import Foundation

/// Decides how long to wait before the next data refresh, based on match state.
///
/// Backs off to hours when nothing is happening and tightens as a kickoff
/// approaches, to stay gentle on the free `worldcup26.ir` API. All thresholds
/// come from the injected `PollingConfiguration`.
public struct PollingIntervalPolicy: Sendable {
    private let config: PollingConfiguration

    public init(configuration: PollingConfiguration = .default) {
        self.config = configuration
    }

    /// - Parameters:
    ///   - matches: the full tournament match set from the latest snapshot.
    ///   - now: the current time.
    /// - Returns: how long to sleep before the next refresh.
    public func interval(for matches: [WorldCupMatch], now: Date) -> Duration {
        if matches.contains(where: { $0.status.isLive }) {
            return config.liveInterval
        }

        // A match still flagged .scheduled whose kickoff time has passed is
        // presumably underway -- the API lags flipping it to .live. Poll
        // aggressively instead of backing off to the idle cap, bounded by the
        // grace window so a stuck scheduled match cannot pin us at liveInterval.
        let justKickedOff = matches.contains { match in
            guard match.status == .scheduled, match.kickoffDate <= now else {
                return false
            }
            return Duration.seconds(now.timeIntervalSince(match.kickoffDate)) <= config.kickoffGraceWindow
        }
        if justKickedOff {
            return config.liveInterval
        }

        let nextKickoff = matches
            .filter { $0.status == .scheduled && $0.kickoffDate >= now }
            .map(\.kickoffDate)
            .min()

        guard let nextKickoff else {
            return config.idleCap
        }

        let timeUntilKickoff = Duration.seconds(nextKickoff.timeIntervalSince(now))
        if timeUntilKickoff <= config.warmupWindow {
            return config.imminentInterval
        }

        let untilWarmup = timeUntilKickoff - config.warmupWindow
        return max(.seconds(60), min(untilWarmup, config.idleCap))
    }
}
