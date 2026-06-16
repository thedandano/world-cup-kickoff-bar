import Testing
@testable import WorldCupBar

@Test func footerPrefersStampedGitDescribe() {
    let text = AppVersion.footer(displayVersion: "1.1.1-9-g6b3d93c", marketingVersion: "1.0.0")
    #expect(text == "v1.1.1-9-g6b3d93c")
}

@Test func footerKeepsDirtyMarker() {
    let text = AppVersion.footer(displayVersion: "1.1.1-9-g6b3d93c-dirty", marketingVersion: nil)
    #expect(text == "v1.1.1-9-g6b3d93c-dirty")
}

@Test func footerFallsBackToMarketingVersion() {
    let text = AppVersion.footer(displayVersion: nil, marketingVersion: "1.1.2")
    #expect(text == "v1.1.2")
}

@Test func footerShowsDevPlaceholderWhenNothingAvailable() {
    let text = AppVersion.footer(displayVersion: nil, marketingVersion: nil)
    #expect(text == "dev build")
}

@Test func footerIgnoresEmptyAndZeroVersions() {
    let text = AppVersion.footer(displayVersion: "", marketingVersion: "0.0.0")
    #expect(text == "dev build")
}
