import Testing
@testable import WorldCupBar

@Test func footerShowsGitDescribeBetweenTags() {
    let version = AppVersion(describe: "v1.1.1-5-g5450215", dirty: false)
    #expect(version.footer == "v1.1.1-5-g5450215")
}

@Test func footerIsCleanTagAtRelease() {
    let version = AppVersion(describe: "v1.1.1", dirty: false)
    #expect(version.footer == "v1.1.1")
}

@Test func footerAppendsDirtyMarker() {
    let version = AppVersion(describe: "v1.1.1-5-g5450215", dirty: true)
    #expect(version.footer == "v1.1.1-5-g5450215-dirty")
}

@Test func footerIsUnknownWhenNoGit() {
    let version = AppVersion(describe: "unknown", dirty: false)
    #expect(version.footer == "unknown")
}

/// Smoke test for the resolution path (bundle stamp → DEBUG runtime fallback).
/// Running inside the repo it yields a `git describe`; with no git it yields
/// `unknown`. Either way it must resolve to a non-empty string without crashing.
@Test func currentResolvesToNonEmptyDescribe() {
    #expect(!AppVersion.current().describe.isEmpty)
}
