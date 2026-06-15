# Releasing World Cup Bar

This project ships as a **notarized, drag-to-Applications DMG** that **auto-updates via Sparkle**. Pushing a `vX.Y.Z` tag triggers `.github/workflows/cd.yml`, which builds, signs, notarizes, packages the DMG, signs the Sparkle appcast, and publishes a GitHub Release.

---

## Local build

Open the app in Xcode and Build & Run (⌘R):

```bash
brew install xcodegen
xcodegen generate
open WorldCupBar.xcodeproj
```

To produce a local DMG for testing, archive the app (Product → Archive → Distribute App → Developer ID, or just copy the built `.app`), then:

```bash
./scripts/make-dmg.sh <path-to-WorldCupBar.app>   # → dist/WorldCupBar-<version>.dmg
```

---

## One-time setup for real (notarized) releases

### 1. Apple Developer Program + Developer ID certificate

Notarized direct distribution requires the **paid** [Apple Developer Program](https://developer.apple.com/programs/) ($99/yr). A free/"Apple Development" certificate **cannot** notarize apps for distribution outside the App Store.

Once enrolled, create a **Developer ID Application** certificate (Xcode → Settings → Accounts → Manage Certificates → +, or developer.apple.com → Certificates). Find your **Team ID** in [Apple Developer → Membership](https://developer.apple.com/account), or run `security find-identity -v -p codesigning` and read the value in parentheses on your *Developer ID Application* identity.

### 2. Sparkle signing key

Sparkle uses an EdDSA **key pair** — keep the two halves straight:

- **Public key** → already in `Info.plist` as `SUPublicEDKey`, ships inside the app, **not a secret** (it only *verifies* updates).
- **Private key** → lives in your login Keychain, **signs** updates, and is what the `SPARKLE_PRIVATE_KEY` secret below must hold. Back it up now — lose it and existing installs can't trust future updates.

Export the **private** key (the `-x` flag exports the private half) and paste its contents into the `SPARKLE_PRIVATE_KEY` secret:

```bash
.build/artifacts/sparkle/Sparkle/bin/generate_keys -x sparkle_private_key.txt
# sparkle_private_key.txt now holds your PRIVATE key — paste its contents into the
# SPARKLE_PRIVATE_KEY GitHub secret, keep a backup (password manager), then delete the file.
```

### 3. GitHub Actions secrets

Set these under **Settings → Secrets and variables → Actions**:

| Secret | How to get it |
|--------|---------------|
| `DEVELOPER_ID_CERT_BASE64` | Export the Developer ID cert as `.p12` from Keychain Access, then `base64 -i cert.p12 \| pbcopy` |
| `DEVELOPER_ID_CERT_PASSWORD` | The password you set when exporting the `.p12` |
| `DEVELOPER_ID_IDENTITY` | The cert's full name, e.g. `Developer ID Application: Your Name (TEAMID)` |
| `APPLE_ID` | Your Apple ID email |
| `APPLE_TEAM_ID` | Your Developer ID team ID (from step 1) |
| `APPLE_APP_PASSWORD` | An [app-specific password](https://support.apple.com/en-us/102654) for notarytool |
| `SPARKLE_PRIVATE_KEY` | Contents of `sparkle_private_key.txt` from step 2 |

### 4. ⚠️ Make the appcast reachable (`SUFeedURL`)

Sparkle checks the URL in `Info.plist` → `SUFeedURL` for updates. The CI uploads `appcast.xml` as a **GitHub Release asset**, so the simplest stable feed is the "latest release" URL. **Update `SUFeedURL` in `Sources/WorldCupBar/Info.plist`** to your repo:

```xml
<key>SUFeedURL</key>
<string>https://github.com/<OWNER>/<REPO>/releases/latest/download/appcast.xml</string>
```

(It currently points at `michilotl.github.io/world-cup-bar/appcast.xml`, which only works if you instead publish `appcast.xml` to GitHub Pages on each release.)

---

## Cutting a release

```bash
# 1. Bump the version in Sources/WorldCupBar/Info.plist (CFBundleShortVersionString)
# 2. Commit, then tag and push:
git tag v1.0.1
git push origin v1.0.1
```

CI then builds the universal app, signs it (Developer ID + hardened runtime), notarizes + staples it, packages the DMG, signs + notarizes + staples the DMG, signs the Sparkle appcast, and publishes the GitHub Release with the `.dmg` + `appcast.xml`. Existing installs pick up the update automatically.
