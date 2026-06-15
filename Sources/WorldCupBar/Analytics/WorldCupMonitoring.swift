import Foundation
import OSLog
import WorldCupBarCore

/// On-device operational logging of refresh activity via `os.Logger`.
/// Nothing leaves the device — no analytics, no third-party SDKs.
final class WorldCupMonitoringService: @unchecked Sendable, WorldCupTelemetry {
    private let log = Logger(subsystem: "com.michilotl.WorldCupBar", category: "monitoring")

    func recordCacheLoaded(matchCount: Int, teamCount: Int) {
        log.info("Cache loaded: matches=\(matchCount) teams=\(teamCount)")
    }

    func recordRefreshStarted(trigger: RefreshTrigger) {
        log.info("Refresh started: trigger=\(trigger.rawValue)")
    }

    func recordRefreshSucceeded(snapshot: WorldCupSnapshot, latency: Duration, attemptCount: Int) {
        let matchCount = snapshot.matches.count
        let latencyMs = latency.inMilliseconds
        log.info("Refresh succeeded: attempts=\(attemptCount) matches=\(matchCount) latency_ms=\(latencyMs)")
    }

    func recordRefreshFailed(error: Error, latency _: Duration?, attemptCount: Int, hasCachedSnapshot: Bool) {
        let reason = error.localizedDescription
        log.error("Refresh failed: attempts=\(attemptCount) has_cache=\(hasCachedSnapshot) error=\(reason)")
    }
}

private extension Duration {
    var inMilliseconds: Int {
        let components = components
        return Int(components.seconds * 1_000) + Int(components.attoseconds / 1_000_000_000_000_000)
    }
}
