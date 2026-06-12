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
    let a = WorldCupSnapshot(matches: [match], countries: [], fetchedAt: Date(timeIntervalSince1970: 1_000))
    let b = WorldCupSnapshot(matches: [match], countries: [], fetchedAt: Date(timeIntervalSince1970: 2_000))

    #expect(a.matchesContentEqual(to: b))
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
    let a = WorldCupSnapshot(matches: [base], countries: [], fetchedAt: Date(timeIntervalSince1970: 1_000))
    let b = WorldCupSnapshot(matches: [updated], countries: [], fetchedAt: Date(timeIntervalSince1970: 2_000))

    #expect(!a.matchesContentEqual(to: b))
}

@Test func contentNotEqualWhenMatchCountDiffers() {
    let m1 = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: Date(timeIntervalSince1970: 1_800_000_000),
        status: .scheduled,
        score: nil,
        venue: "NYC"
    )
    let m2 = WorldCupMatch(
        id: "can-bra",
        home: .canada,
        away: .brazil,
        kickoffDate: Date(timeIntervalSince1970: 1_800_003_600),
        status: .scheduled,
        score: nil,
        venue: "Toronto"
    )
    let a = WorldCupSnapshot(matches: [m1], countries: [], fetchedAt: Date(timeIntervalSince1970: 1_000))
    let b = WorldCupSnapshot(matches: [m1, m2], countries: [], fetchedAt: Date(timeIntervalSince1970: 1_000))

    #expect(!a.matchesContentEqual(to: b))
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
    let a = WorldCupSnapshot(matches: [scheduled], countries: [], fetchedAt: Date(timeIntervalSince1970: 1_000))
    let b = WorldCupSnapshot(matches: [live], countries: [], fetchedAt: Date(timeIntervalSince1970: 2_000))

    #expect(!a.matchesContentEqual(to: b))
}
