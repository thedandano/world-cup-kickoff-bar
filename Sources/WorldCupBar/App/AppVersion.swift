import Foundation

/// Version + git build metadata read from the app bundle, plus the pure
/// formatting logic for the Settings footer. Keeping `footerText` pure (no
/// bundle, no view) makes the composition unit-testable.
struct AppVersion {
    let version: String
    let build: String
    let sha: String
    let dirty: Bool

    static func fromBundle(_ bundle: Bundle = .main) -> AppVersion {
        func string(_ key: String, default def: String) -> String {
            (bundle.object(forInfoDictionaryKey: key) as? String) ?? def
        }
        let dirtyValue = bundle.object(forInfoDictionaryKey: "GitDirty")
        let dirty = (dirtyValue as? Bool) ?? ((dirtyValue as? String) == "true")
        return AppVersion(
            version: string("CFBundleShortVersionString", default: "0.0.0"),
            build: string("CFBundleVersion", default: "0"),
            sha: string("GitSHA", default: "unknown"),
            dirty: dirty
        )
    }

    /// Pure formatter. `isDebug` decides whether git detail is appended;
    /// Release builds get the clean `v{version} (build {build})` form.
    static func footerText(
        version: String, build: String, sha: String, dirty: Bool, isDebug: Bool
    ) -> String {
        let base = "v\(version) (build \(build))"
        guard isDebug else { return base }
        return "\(base) · \(sha)\(dirty ? "-dirty" : "")"
    }

    /// Bundle-derived footer string with build-config gating baked in.
    var footer: String {
        #if DEBUG
        return Self.footerText(version: version, build: build, sha: sha, dirty: dirty, isDebug: true)
        #else
        return Self.footerText(version: version, build: build, sha: sha, dirty: dirty, isDebug: false)
        #endif
    }
}
