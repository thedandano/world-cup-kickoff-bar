import Testing
@testable import WorldCupBar

@Test func footerReleaseHidesGitDetail() {
    let text = AppVersion.footerText(
        version: "1.1.1", build: "42", sha: "90ed77e", dirty: true, isDebug: false
    )
    #expect(text == "v1.1.1 (build 42)")
}

@Test func footerDebugCleanShowsSha() {
    let text = AppVersion.footerText(
        version: "1.1.1", build: "1", sha: "90ed77e", dirty: false, isDebug: true
    )
    #expect(text == "v1.1.1 (build 1) · 90ed77e")
}

@Test func footerDebugDirtyAppendsDirty() {
    let text = AppVersion.footerText(
        version: "1.1.1", build: "1", sha: "90ed77e", dirty: true, isDebug: true
    )
    #expect(text == "v1.1.1 (build 1) · 90ed77e-dirty")
}

@Test func footerDebugUnknownShaWhenNoGit() {
    let text = AppVersion.footerText(
        version: "1.1.1", build: "1", sha: "unknown", dirty: false, isDebug: true
    )
    #expect(text == "v1.1.1 (build 1) · unknown")
}
