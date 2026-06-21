import Foundation
import Testing
@testable import WorldCupBarCore

private let now = Date(timeIntervalSince1970: 1_800_000_000)

private func match(
    id: String,
    kickoffOffset: TimeInterval,
    status: MatchStatus
) -> WorldCupMatch {
    WorldCupMatch(
        id: id,
        home: .unitedStates,
        away: .mexico,
        kickoffDate: now.addingTimeInterval(kickoffOffset),
        status: status,
        score: nil,
        venue: "Test Stadium"
    )
}

@Test func liveWithUnknownMinuteStillPolls30Seconds() {
    let matches = [match(id: "live-nil", kickoffOffset: -600, status: .live(minute: nil))]
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(30))
}

@Test func liveMatchPollsEvery30Seconds() {
    let matches = [
        match(id: "live", kickoffOffset: -3_600, status: .live(minute: 50)),
        match(id: "later", kickoffOffset: 7_200, status: .scheduled)
    ]
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(30))
}

@Test func liveTakesPriorityOverImminentKickoff() {
    let matches = [
        match(id: "imminent", kickoffOffset: 600, status: .scheduled),
        match(id: "live", kickoffOffset: -1_200, status: .live(minute: 20))
    ]
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(30))
}

@Test func kickoffWithinWarmupWindowPollsEveryMinute() {
    let matches = [match(id: "soon", kickoffOffset: 5 * 60, status: .scheduled)]
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(60))
}

@Test func kickoffExactlyAtWarmupBoundaryPollsEveryMinute() {
    let matches = [match(id: "boundary", kickoffOffset: 10 * 60, status: .scheduled)]
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(60))
}

@Test func kickoffJustPastWarmupBoundaryIsFlooredAt60Seconds() {
    let matches = [match(id: "justpast", kickoffOffset: 10 * 60 + 1, status: .scheduled)]
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(60))
}

@Test func kickoff40MinutesOutSleepsUntilWarmupWindow() {
    let matches = [match(id: "40min", kickoffOffset: 40 * 60, status: .scheduled)]
    // 40min - 10min warm-up = 30min, under the 3h cap.
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(30 * 60))
}

@Test func kickoffManyHoursOutIsCappedAtThreeHours() {
    let matches = [match(id: "5h", kickoffOffset: 5 * 60 * 60, status: .scheduled)]
    // 5h - 10min = 4h50m, capped to 3h.
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(3 * 60 * 60))
}

@Test func usesSoonestUpcomingKickoff() {
    let matches = [
        match(id: "far", kickoffOffset: 10 * 60 * 60, status: .scheduled),
        match(id: "soon", kickoffOffset: 5 * 60, status: .scheduled)
    ]
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(60))
}

@Test func recentlyPastScheduledKickoffPollsLive() {
    // Kickoff time passed but the API hasn't flipped to .live yet: treat it as
    // underway and poll at liveInterval instead of backing off to the idle cap.
    let matches = [
        match(id: "justkicked", kickoffOffset: -60, status: .scheduled),
        match(id: "future", kickoffOffset: 5 * 60 * 60, status: .scheduled)
    ]
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(30))
}

@Test func scheduledKickoffJustInsideGraceWindowPollsLive() {
    // Within the 3h grace window (default kickoffGraceWindow).
    let matches = [match(id: "stillon", kickoffOffset: -(3 * 60 * 60 - 60), status: .scheduled)]
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(30))
}

@Test func scheduledKickoffBeyondGraceWindowCapsAtThreeHours() {
    // Past the grace window: a stuck scheduled match must not pin us at liveInterval.
    let matches = [match(id: "stale", kickoffOffset: -(4 * 60 * 60), status: .scheduled)]
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(3 * 60 * 60))
}

@Test func noUpcomingMatchesCapsAtThreeHours() {
    let matches = [match(id: "done", kickoffOffset: -7_200, status: .finished)]
    #expect(PollingIntervalPolicy().interval(for: matches, now: now) == .seconds(3 * 60 * 60))
}

@Test func emptyMatchesCapsAtThreeHours() {
    #expect(PollingIntervalPolicy().interval(for: [], now: now) == .seconds(3 * 60 * 60))
}

@Test func customConfigurationOverridesIntervals() {
    let config = PollingConfiguration(
        liveInterval: .seconds(15),
        imminentInterval: .seconds(45),
        warmupWindow: .seconds(5 * 60),
        idleCap: .seconds(6 * 60 * 60)
    )
    let policy = PollingIntervalPolicy(configuration: config)
    let live = [match(id: "live", kickoffOffset: -600, status: .live(minute: 10))]
    let imminent = [match(id: "soon", kickoffOffset: 3 * 60, status: .scheduled)]
    let idle = [match(id: "far", kickoffOffset: 24 * 60 * 60, status: .scheduled)]

    #expect(policy.interval(for: live, now: now) == .seconds(15))
    #expect(policy.interval(for: imminent, now: now) == .seconds(45))
    #expect(policy.interval(for: idle, now: now) == .seconds(6 * 60 * 60))
}
