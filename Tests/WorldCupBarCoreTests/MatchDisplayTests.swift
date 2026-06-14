import Foundation
import Testing
@testable import WorldCupBarCore

@Test func liveScoreAppearsInCompactMenuBarWhenTrackedMatchIsLive() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let liveMatch = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: now.addingTimeInterval(-3_600),
        status: .live(minute: 67),
        score: MatchScore(home: 1, away: 0),
        venue: "Estadio Azteca"
    )
    let upcomingMatch = WorldCupMatch(
        id: "can-bra",
        home: .canada,
        away: .brazil,
        kickoffDate: now.addingTimeInterval(7_200),
        status: .scheduled,
        score: nil,
        venue: "BMO Field"
    )

    let state = MatchSelectionService().displayState(
        matches: [upcomingMatch, liveMatch],
        followedCountryCodes: ["USA"],
        now: now
    )
    let title = MatchFormatter(timeZone: TimeZone(secondsFromGMT: 0)!).menuBarTitle(
        for: state,
        displayMode: .abbreviations
    )

    #expect(state == .live(liveMatch))
    #expect(title == "USA 1-0 MEX")
}

@Test func upcomingLocalTimeAppearsWhenNoTrackedMatchIsLive() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let upcomingMatch = WorldCupMatch(
        id: "can-bra",
        home: .canada,
        away: .brazil,
        kickoffDate: Date(timeIntervalSince1970: 1_800_018_000),
        status: .scheduled,
        score: nil,
        venue: "BMO Field"
    )

    let state = MatchSelectionService().displayState(
        matches: [upcomingMatch],
        followedCountryCodes: ["CAN"],
        now: now
    )
    let title = MatchFormatter(
        timeZone: TimeZone(secondsFromGMT: 0)!,
        locale: Locale(identifier: "en_US_POSIX")
    ).menuBarTitle(for: state, displayMode: .abbreviations)

    #expect(state == .upcoming(upcomingMatch))
    #expect(title.hasPrefix("CAN v BRA 1:00"))
    #expect(title.hasSuffix("PM"))
}

@Test func flagsDisplayModeChangesCompactLabels() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let liveMatch = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: now.addingTimeInterval(-3_600),
        status: .live(minute: 23),
        score: MatchScore(home: 2, away: 1),
        venue: "Estadio Azteca"
    )

    let title = MatchFormatter(timeZone: TimeZone(secondsFromGMT: 0)!).menuBarTitle(
        for: .live(liveMatch),
        displayMode: .flags
    )

    #expect(title == "🇺🇸 2-1 🇲🇽")
}

@Test func followedCountryFilteringControlsMatchPriority() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let unrelatedSoonerMatch = WorldCupMatch(
        id: "arg-fra",
        home: .argentina,
        away: .france,
        kickoffDate: now.addingTimeInterval(900),
        status: .scheduled,
        score: nil,
        venue: "MetLife Stadium"
    )
    let followedLaterMatch = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: now.addingTimeInterval(3_600),
        status: .scheduled,
        score: nil,
        venue: "Estadio Azteca"
    )

    let state = MatchSelectionService().displayState(
        matches: [unrelatedSoonerMatch, followedLaterMatch],
        followedCountryCodes: ["USA"],
        now: now
    )

    #expect(state == .upcoming(followedLaterMatch))
}

@Test func multipleLiveMatchesChooseMostUrgentLiveGame() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let earlyLiveMatch = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: now.addingTimeInterval(-1_200),
        status: .live(minute: 20),
        score: MatchScore(home: 0, away: 0),
        venue: "Estadio Azteca"
    )
    let lateLiveMatch = WorldCupMatch(
        id: "can-bra",
        home: .canada,
        away: .brazil,
        kickoffDate: now.addingTimeInterval(-4_800),
        status: .live(minute: 82),
        score: MatchScore(home: 1, away: 2),
        venue: "BMO Field"
    )

    let state = MatchSelectionService().displayState(
        matches: [earlyLiveMatch, lateLiveMatch],
        followedCountryCodes: ["USA", "CAN"],
        now: now
    )

    #expect(state == .live(lateLiveMatch))
}

@Test func fallbackShowsNextTournamentMatchWhenFollowedCountriesHaveNoMatch() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let nextTournamentMatch = WorldCupMatch(
        id: "arg-fra",
        home: .argentina,
        away: .france,
        kickoffDate: now.addingTimeInterval(1_800),
        status: .scheduled,
        score: nil,
        venue: "MetLife Stadium"
    )

    let state = MatchSelectionService().displayState(
        matches: [nextTournamentMatch],
        followedCountryCodes: ["USA"],
        now: now
    )

    #expect(state == .upcoming(nextTournamentMatch))
}

@Test func liveStatusLineUsesSoccerMinuteMarker() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let liveMatch = WorldCupMatch(
        id: "usa-mex",
        home: .unitedStates,
        away: .mexico,
        kickoffDate: now.addingTimeInterval(-3_600),
        status: .live(minute: 67),
        score: MatchScore(home: 1, away: 0),
        venue: "Estadio Azteca"
    )

    #expect(MatchFormatter().statusLine(for: liveMatch) == "Live 67'")
}

@Test func postTournamentStateRequiresFinishedTournamentWithoutFutureMatches() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let finishedMatch = WorldCupMatch(
        id: "final",
        home: .argentina,
        away: .france,
        kickoffDate: now.addingTimeInterval(-86_400),
        status: .finished,
        score: MatchScore(home: 3, away: 2),
        venue: "MetLife Stadium"
    )

    #expect(MatchSelectionService().isPostTournamentState(matches: [finishedMatch], now: now))
}

@Test func spotlightPrefersMostUrgentLiveMatchOverUpcoming() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let liveMatch = WorldCupMatch(
        id: "live", home: .unitedStates, away: .mexico,
        kickoffDate: now.addingTimeInterval(-3_000), status: .live(minute: 80),
        score: MatchScore(home: 1, away: 0), venue: "Estadio Azteca"
    )
    let upcomingMatch = WorldCupMatch(
        id: "soon", home: .argentina, away: .france,
        kickoffDate: now.addingTimeInterval(1_800), status: .scheduled,
        score: nil, venue: "MetLife Stadium"
    )

    let state = MatchSelectionService().spotlight(from: [upcomingMatch, liveMatch], now: now)

    #expect(state == .live(liveMatch))
}

@Test func spotlightReturnsNextUpcomingWhenNoLiveMatch() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let later = WorldCupMatch(
        id: "later", home: .germany, away: .japan,
        kickoffDate: now.addingTimeInterval(7_200), status: .scheduled,
        score: nil, venue: "Lumen Field"
    )
    let sooner = WorldCupMatch(
        id: "sooner", home: .argentina, away: .france,
        kickoffDate: now.addingTimeInterval(1_800), status: .scheduled,
        score: nil, venue: "MetLife Stadium"
    )

    let state = MatchSelectionService().spotlight(from: [later, sooner], now: now)

    #expect(state == .upcoming(sooner))
}

@Test func spotlightIsEmptyWhenNoLiveOrUpcomingMatches() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let finished = WorldCupMatch(
        id: "done", home: .brazil, away: .germany,
        kickoffDate: now.addingTimeInterval(-86_400), status: .finished,
        score: MatchScore(home: 2, away: 1), venue: "SoFi Stadium"
    )

    let state = MatchSelectionService().spotlight(from: [finished], now: now)

    #expect(state == .empty)
}
