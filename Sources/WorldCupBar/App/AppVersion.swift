import Foundation

/// The version string shown in the Settings footer.
///
/// - **Release builds** show the marketing version that CI injects from the git
///   tag (`CFBundleShortVersionString` ← `MARKETING_VERSION="${GIT_TAG#v}"`), so
///   prod never depends on git history at build time — CI checkouts are shallow
///   and have no tags, which would break `git describe`.
/// - **Debug builds** show `git describe` for precise local build identity: the
///   Info.plist value stamped by `scripts/stamp-git-info.sh` (used by the
///   sandboxed local `.app`), or a runtime `git describe` for the non-sandboxed
///   dev binary (`swift run`).
enum AppVersion {
    static func footer(bundle: Bundle = .main) -> String {
        #if DEBUG
        let resolved = debugVersion(bundle: bundle)
        return devFooter(describe: resolved.describe, dirty: resolved.dirty)
        #else
        return releaseFooter(marketingVersion: marketingVersion(bundle: bundle))
        #endif
    }

    // MARK: - Pure formatters (unit-tested)

    /// Release footer: the marketing version, e.g. `v1.1.2`.
    static func releaseFooter(marketingVersion: String) -> String {
        "v\(marketingVersion)"
    }

    /// Debug footer: `git describe` with a `-dirty` marker, e.g.
    /// `v1.1.1-5-g5450215-dirty`, or just `v1.1.1` at a tag.
    static func devFooter(describe: String, dirty: Bool) -> String {
        dirty ? "\(describe)-dirty" : describe
    }

    static func marketingVersion(bundle: Bundle) -> String {
        (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0.0.0"
    }
}

#if DEBUG
extension AppVersion {
    /// `git describe` + dirty for local builds: the Info.plist stamp first
    /// (present in the sandboxed `.app`), then a runtime read (dev binary).
    static func debugVersion(bundle: Bundle) -> (describe: String, dirty: Bool) {
        if let stamped = bundle.object(forInfoDictionaryKey: "GitDescribe") as? String,
           !stamped.isEmpty, stamped != "unknown" {
            let value = bundle.object(forInfoDictionaryKey: "GitDirty")
            let dirty = (value as? Bool) ?? ((value as? String) == "true")
            return (stamped, dirty)
        }
        if let runtime = runtimeDescribe() {
            return runtime
        }
        return ("unknown", false)
    }

    /// Reads `git describe` at runtime for the non-sandboxed dev binary
    /// (`swift run`). Anchors on the working directory first — the repo root
    /// when launched from it — then this file's directory. (`#filePath` can
    /// compile to a relative path, so it can't be the only anchor.)
    static func runtimeDescribe() -> (describe: String, dirty: Bool)? {
        let candidates = [
            FileManager.default.currentDirectoryPath,
            URL(fileURLWithPath: #filePath).deletingLastPathComponent().path
        ]
        for dir in candidates {
            guard let root = git(["-C", dir, "rev-parse", "--show-toplevel"]), !root.isEmpty,
                  let describe = git(["-C", root, "describe", "--tags", "--always", "--abbrev=7"]),
                  !describe.isEmpty
            else { continue }
            let status = git(["-C", root, "status", "--porcelain", "--", "Sources", "project.yml"]) ?? ""
            return (describe, !status.isEmpty)
        }
        return nil
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
