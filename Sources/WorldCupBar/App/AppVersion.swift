import Foundation

/// The version string shown in the Settings footer.
///
/// The app reads `DisplayVersion` from its Info.plist — written by
/// `scripts/stamp-git-info.sh` as `git describe` for local **Debug** builds — and
/// otherwise falls back to `CFBundleShortVersionString`, the marketing version CI
/// injects from the release tag (`MARKETING_VERSION="${GIT_TAG#v}"`). The
/// release-vs-dev decision lives in the build script (by `CONFIGURATION`), so the
/// Swift side stays trivial and prod never depends on git history.
///
/// Note: the SwiftPM dev binary (`swift run`) has no processed Info.plist, so it
/// shows the dev placeholder — run the app target (⌘R) for an accurate footer.
enum AppVersion {
    static func footer(bundle: Bundle = .main) -> String {
        footer(
            displayVersion: bundle.object(forInfoDictionaryKey: "DisplayVersion") as? String,
            marketingVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        )
    }

    /// Pure formatter: prefer the stamped `git describe`, then the marketing
    /// version, else a dev placeholder. Empty / `0.0.0` values are ignored.
    static func footer(displayVersion: String?, marketingVersion: String?) -> String {
        for candidate in [displayVersion, marketingVersion] {
            if let version = candidate, !version.isEmpty, version != "0.0.0" {
                return "v\(version)"
            }
        }
        return "dev build"
    }
}
