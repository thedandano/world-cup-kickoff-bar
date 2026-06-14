import Foundation
import Testing
@testable import WorldCupBarCore

@Test func contentEqualIgnoresFetchedAtTimestamp() {
    let match = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .scheduled,
        score: nil,
        venue: "NYC"
    )
    let snapshotWithOldTimestamp = WorldCupSnapshot(
        matches: [match], countries: [], fetchedAt: Date(timeIntervalSince1970: 1_000)
    )
    let snapshotWithNewTimestamp = WorldCupSnapshot(
        matches: [match], countries: [], fetchedAt: Date(timeIntervalSince1970: 2_000)
    )

    #expect(snapshotWithOldTimestamp.matchesContentEqual(to: snapshotWithNewTimestamp))
}

@Test func contentNotEqualWhenScoreChanges() {
    let base = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .live(minute: 45),
        score: MatchScore(home: 0, away: 0),
        venue: "NYC"
    )
    let updated = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .live(minute: 67),
        score: MatchScore(home: 1, away: 0),
        venue: "NYC"
    )
    let snapshotWithBaseMatch = WorldCupSnapshot(
        matches: [base], countries: [], fetchedAt: Date(timeIntervalSince1970: 1_000)
    )
    let snapshotWithUpdatedMatch = WorldCupSnapshot(
        matches: [updated], countries: [], fetchedAt: Date(timeIntervalSince1970: 2_000)
    )

    #expect(!snapshotWithBaseMatch.matchesContentEqual(to: snapshotWithUpdatedMatch))
}

@Test func contentNotEqualWhenMatchCountDiffers() {
    let usaMexMatch = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .scheduled,
        score: nil,
        venue: "NYC"
    )
    let canadaBrazilMatch = WorldCupMatch(
        id: "can-bra",
        home: .canada,
        away: .brazil,
        kickoffDate: Date(timeIntervalSince1970: 1_800_003_600),
        status: .scheduled,
        score: nil,
        venue: "Toronto"
    )
    let snapshotWithOneMatch = WorldCupSnapshot(
        matches: [usaMexMatch], countries: [], fetchedAt: Date(timeIntervalSince1970: 1_000)
    )
    let snapshotWithTwoMatches = WorldCupSnapshot(
        matches: [usaMexMatch, canadaBrazilMatch],
        countries: [],
        fetchedAt: Date(timeIntervalSince1970: 1_000)
    )

    #expect(!snapshotWithOneMatch.matchesContentEqual(to: snapshotWithTwoMatches))
}

@Test func contentNotEqualWhenStatusChangesFromScheduledToLive() {
    let scheduled = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .scheduled,
        score: nil,
        venue: "NYC"
    )
    let live = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .live(minute: 1),
        score: MatchScore(home: 0, away: 0),
        venue: "NYC"
    )
    let scheduledSnapshot = WorldCupSnapshot(
        matches: [scheduled], countries: [], fetchedAt: Date(timeIntervalSince1970: 1_000)
    )
    let liveSnapshot = WorldCupSnapshot(
        matches: [live], countries: [], fetchedAt: Date(timeIntervalSince1970: 2_000)
    )

    #expect(!scheduledSnapshot.matchesContentEqual(to: liveSnapshot))
}
