import Foundation

public protocol WorldCupTelemetry: Sendable {
    func recordCacheLoaded(matchCount: Int, teamCount: Int)
    func recordRefreshStarted(trigger: RefreshTrigger)
    func recordRefreshSucceeded(snapshot: WorldCupSnapshot, latency: Duration, attemptCount: Int)
    func recordRefreshFailed(error: Error, latency: Duration?, attemptCount: Int, hasCachedSnapshot: Bool)
}

public enum RefreshTrigger: String, Codable, Sendable {
    case appLaunch
    case manual
    case automatic
}

public struct NoOpWorldCupTelemetry: WorldCupTelemetry {
    public init() {}

    public func recordCacheLoaded(matchCount: Int, teamCount: Int) {}
    public func recordRefreshStarted(trigger: RefreshTrigger) {}
    public func recordRefreshSucceeded(snapshot: WorldCupSnapshot, latency: Duration, attemptCount: Int) {}
    public func recordRefreshFailed(error: Error, latency: Duration?, attemptCount: Int, hasCachedSnapshot: Bool) {}
}
