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

    public func recordCacheLoaded(matchCount _: Int, teamCount _: Int) {}
    public func recordRefreshStarted(trigger _: RefreshTrigger) {}
    public func recordRefreshSucceeded(snapshot _: WorldCupSnapshot, latency _: Duration, attemptCount _: Int) {}
    public func recordRefreshFailed(error _: Error, latency _: Duration?, attemptCount _: Int, hasCachedSnapshot _: Bool) {}
}
