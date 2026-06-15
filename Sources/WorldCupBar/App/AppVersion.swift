import Foundation

/// The app's version string for the Settings footer, derived from `git describe`
/// (e.g. `v1.1.1-5-g5450215`, or just `v1.1.1` exactly at a release tag).
///
/// The value is produced at build time by `scripts/stamp-git-info.sh`, which
/// writes it into the bundle's Info.plist. When that stamp is absent — e.g.
/// running the SwiftPM dev binary via `swift run`, which has no processed
/// Info.plist — a DEBUG-only runtime `git describe` keeps the footer accurate in
/// development. The sandboxed release app can't exec git, so it relies on the
/// stamp.
struct AppVersion {
    /// Output of `git describe --tags --always`, or `unknown` with no git.
    let describe: String
    /// Whether build inputs (`Sources/`, `project.yml`) had uncommitted changes.
    let dirty: Bool

    /// The footer string: the git description with a `-dirty` marker appended.
    var footer: String {
        dirty ? "\(describe)-dirty" : describe
    }

    /// Resolves the current version: the build-time Info.plist stamp first,
    /// then a DEBUG-only runtime `git describe` fallback for dev binaries.
    static func current(bundle: Bundle = .main) -> AppVersion {
        if let stamped = bundle.object(forInfoDictionaryKey: "GitDescribe") as? String,
           !stamped.isEmpty, stamped != "unknown" {
            return AppVersion(describe: stamped, dirty: bundleDirty(bundle))
        }
        #if DEBUG
        if let runtime = runtimeDescribe() {
            return runtime
        }
        #endif
        return AppVersion(describe: "unknown", dirty: false)
    }

    private static func bundleDirty(_ bundle: Bundle) -> Bool {
        let value = bundle.object(forInfoDictionaryKey: "GitDirty")
        return (value as? Bool) ?? ((value as? String) == "true")
    }
}

#if DEBUG
private extension AppVersion {
    /// Reads `git describe` at runtime, scoped to this checkout. Only reached by
    /// the non-sandboxed dev binary (the sandboxed app can't exec git).
    static func runtimeDescribe() -> AppVersion? {
        let sourceDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path
        guard let root = git(["-C", sourceDir, "rev-parse", "--show-toplevel"]), !root.isEmpty,
              let describe = git(["-C", root, "describe", "--tags", "--always", "--abbrev=7"]),
              !describe.isEmpty
        else { return nil }
        let status = git(["-C", root, "status", "--porcelain", "--", "Sources", "project.yml"]) ?? ""
        return AppVersion(describe: describe, dirty: !status.isEmpty)
    }

    static func git(_ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()
        guard (try? process.run()) != nil else { return nil }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
#endif
