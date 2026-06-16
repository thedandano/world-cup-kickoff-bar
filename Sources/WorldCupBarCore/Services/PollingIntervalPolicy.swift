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

        let nextKickoff = matches
            .filter { $0.status == .scheduled && $0.kickoffDate >= now }
            .map(\.kickoffDate)
            .min()

        guard let nextKickoff else {
            return .seconds(config.idleCap)
        }

        let timeUntilKickoff = nextKickoff.timeIntervalSince(now)
        if timeUntilKickoff <= config.warmupWindow {
            return config.imminentInterval
        }

        let untilWarmup = timeUntilKickoff - config.warmupWindow
        let idleSeconds = max(60, min(untilWarmup, config.idleCap))
        return .seconds(idleSeconds)
    }
}
