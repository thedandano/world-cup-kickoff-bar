import Foundation

public struct RetryPolicy: Sendable {
    public let maxAttempts: Int
    public let baseDelay: Duration
    public let maxJitterNanoseconds: UInt64
    public let sleep: @Sendable (Duration) async throws -> Void

    public init(
        maxAttempts: Int = 3,
        baseDelay: Duration = .seconds(1),
        maxJitterNanoseconds: UInt64 = 250_000_000,
        sleep: @escaping @Sendable (Duration) async throws -> Void = { duration in
            try await Task.sleep(for: duration)
        }
    ) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxJitterNanoseconds = maxJitterNanoseconds
        self.sleep = sleep
    }

    public func execute<T: Sendable>(
        operation: @escaping @Sendable () async throws -> T,
        shouldRetry: @escaping @Sendable (Error) -> RetryDirective
    ) async throws -> RetryResult<T> {
        var attempt = 0

        while true {
            attempt += 1

            do {
                return RetryResult(value: try await operation(), attemptCount: attempt)
            } catch {
                let directive = shouldRetry(error)
                let canRetry = attempt < maxAttempts

                guard canRetry, directive.shouldRetry else {
                    throw error
                }

                let delay = directive.overrideDelay ?? delayForAttempt(attempt)
                try await sleep(delay)
            }
        }
    }

    private func delayForAttempt(_ attempt: Int) -> Duration {
        let exponent = max(0, attempt - 1)
        let multiplier = 1 << exponent
        let baseNanoseconds = UInt64(baseDelay.components.seconds) * 1_000_000_000
            + UInt64(baseDelay.components.attoseconds / 1_000_000_000)
        let jitter = maxJitterNanoseconds == 0 ? 0 : UInt64.random(in: 0...maxJitterNanoseconds)
        return .nanoseconds(baseNanoseconds * UInt64(multiplier) + jitter)
    }
}

public struct RetryDirective: Sendable {
    public let shouldRetry: Bool
    public let overrideDelay: Duration?

    public init(shouldRetry: Bool, overrideDelay: Duration? = nil) {
        self.shouldRetry = shouldRetry
        self.overrideDelay = overrideDelay
    }

    public static let noRetry = RetryDirective(shouldRetry: false)
    public static let retry = RetryDirective(shouldRetry: true)
}

public struct RetryResult<T: Sendable>: Sendable {
    public let value: T
    public let attemptCount: Int

    public init(value: T, attemptCount: Int) {
        self.value = value
        self.attemptCount = attemptCount
    }
}
