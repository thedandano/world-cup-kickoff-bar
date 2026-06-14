import Foundation
import OSLog
import TelemetryDeck
import WorldCupBarCore

protocol WorldCupAnalyticsTracking: Sendable {
    func setAnalyticsEnabled(_ isEnabled: Bool)
    func recordUserAction(_ name: String, properties: [String: String])
}

struct MonitoringConfiguration: Sendable {
    let telemetryDeckAppID: String?

    static func fromEnvironment() -> MonitoringConfiguration {
        MonitoringConfiguration(
            telemetryDeckAppID: ProcessInfo.processInfo.environment["WORLD_CUP_BAR_TELEMETRYDECK_APP_ID"]
        )
    }
}

final class WorldCupMonitoringService: @unchecked Sendable, WorldCupTelemetry, WorldCupAnalyticsTracking {
    private let log = Logger(subsystem: "com.michilotl.WorldCupBar", category: "monitoring")
    private let telemetryDeckAppID: String?
    private var analyticsEnabled = true

    init(configuration: MonitoringConfiguration) {
        self.telemetryDeckAppID = configuration.telemetryDeckAppID

        if let appID = configuration.telemetryDeckAppID, !appID.isEmpty {
            TelemetryDeck.initialize(config: .init(appID: appID))
        }
    }

    func setAnalyticsEnabled(_ isEnabled: Bool) {
        analyticsEnabled = isEnabled
    }

    func recordCacheLoaded(matchCount: Int, teamCount: Int) {
        log.info("Cache loaded: matches=\(matchCount) teams=\(teamCount)")
    }

    func recordRefreshStarted(trigger: RefreshTrigger) {
        log.info("Refresh started: trigger=\(trigger.rawValue)")
        recordUserAction("refresh_started", properties: ["trigger": trigger.rawValue])
    }

    func recordRefreshSucceeded(snapshot: WorldCupSnapshot, latency: Duration, attemptCount: Int) {
        let matchCount = snapshot.matches.count
        let latencyMs = latency.inMilliseconds
        log.info("Refresh succeeded: attempts=\(attemptCount) matches=\(matchCount) latency_ms=\(latencyMs)")
        recordUserAction("refresh_succeeded", properties: [
            "attempts": "\(attemptCount)",
            "matches": "\(matchCount)",
            "latency_ms": "\(latencyMs)"
        ])
    }

    func recordRefreshFailed(error: Error, latency _: Duration?, attemptCount: Int, hasCachedSnapshot: Bool) {
        let reason = error.localizedDescription
        log.error("Refresh failed: attempts=\(attemptCount) has_cache=\(hasCachedSnapshot) error=\(reason)")
        recordUserAction("refresh_failed", properties: [
            "attempts": "\(attemptCount)",
            "has_cache": hasCachedSnapshot ? "true" : "false"
        ])
    }

    func recordUserAction(_ name: String, properties: [String: String] = [:]) {
        guard analyticsEnabled, telemetryDeckAppID != nil else {
            return
        }

        TelemetryDeck.signal(name, parameters: properties)
    }
}

private extension Duration {
    var inMilliseconds: Int {
        let components = components
        return Int(components.seconds * 1_000) + Int(components.attoseconds / 1_000_000_000_000_000)
    }
}
