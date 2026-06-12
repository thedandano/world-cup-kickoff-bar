import Foundation
import Testing
@testable import WorldCupBarCore

private final class Counter: @unchecked Sendable {
    var value = 0
}

private final class DurationLog: @unchecked Sendable {
    var values: [Duration] = []
}

@Test func retryPolicyRetriesTransientFailuresAndEventuallySucceeds() async throws {
    let retryPolicy = RetryPolicy(
        maxAttempts: 3,
        baseDelay: .seconds(1),
        maxJitterNanoseconds: 0,
        sleep: { _ in }
    )
    let counter = Counter()

    let result = try await retryPolicy.execute(
        operation: {
            counter.value += 1
            if counter.value < 3 {
                throw URLError(.timedOut)
            }
            return "ok"
        },
        shouldRetry: { error in
            if error is URLError {
                return .retry
            }
            return .noRetry
        }
    )

    #expect(result.value == "ok")
    #expect(result.attemptCount == 3)
}

@Test func retryPolicyDoesNotRetryNonRetriableFailures() async throws {
    let retryPolicy = RetryPolicy(
        maxAttempts: 3,
        baseDelay: .seconds(1),
        maxJitterNanoseconds: 0,
        sleep: { _ in }
    )
    let counter = Counter()

    do {
        _ = try await retryPolicy.execute(
            operation: {
                counter.value += 1
                throw URLError(.badURL)
            },
            shouldRetry: { _ in .noRetry }
        )
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error is URLError)
    }

    #expect(counter.value == 1)
}

@Test func retryPolicyHonorsRetryAfterOverrideDelay() async throws {
    let log = DurationLog()
    let retryPolicy = RetryPolicy(
        maxAttempts: 2,
        baseDelay: .seconds(10),
        maxJitterNanoseconds: 0,
        sleep: { duration in log.values.append(duration) }
    )
    let counter = Counter()

    do {
        _ = try await retryPolicy.execute(
            operation: {
                counter.value += 1
                throw WorldCupDataError.httpStatus(code: 429, retryAfter: .seconds(5))
            },
            shouldRetry: { error in
                if let dataError = error as? WorldCupDataError,
                   case .httpStatus(let code, let retryAfter) = dataError, code == 429 {
                    return RetryDirective(shouldRetry: true, overrideDelay: retryAfter)
                }
                return .noRetry
            }
        )
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(counter.value == 2)
        #expect(log.values == [.seconds(5)])
    }
}
