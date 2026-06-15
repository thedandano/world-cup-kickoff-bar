import Testing
@testable import WorldCupBar

@Test func releaseFooterShowsMarketingVersion() {
    #expect(AppVersion.releaseFooter(marketingVersion: "1.1.2") == "v1.1.2")
}

@Test func devFooterShowsGitDescribe() {
    #expect(AppVersion.devFooter(describe: "v1.1.1-5-g5450215", dirty: false) == "v1.1.1-5-g5450215")
}

@Test func devFooterShowsCleanTag() {
    #expect(AppVersion.devFooter(describe: "v1.1.1", dirty: false) == "v1.1.1")
}

@Test func devFooterAppendsDirtyMarker() {
    #expect(AppVersion.devFooter(describe: "v1.1.1-5-g5450215", dirty: true) == "v1.1.1-5-g5450215-dirty")
}

@Test func devFooterIsUnknownWhenNoGit() {
    #expect(AppVersion.devFooter(describe: "unknown", dirty: false) == "unknown")
}

/// Smoke test: resolution must yield a non-empty string without crashing
/// (Debug → git describe or "unknown"; Release → "v" + marketing version).
@Test func footerResolvesToNonEmpty() {
    #expect(!AppVersion.footer().isEmpty)
}
