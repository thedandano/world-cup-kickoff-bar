#!/usr/bin/env bash
#
# build-app.sh — assemble "World Cup Bar.app" from the SwiftPM build.
# `swift build` alone only produces a bare binary that Finder opens in Terminal;
# this wraps it in a proper macOS app bundle: embeds Sparkle.framework (the
# binary links it via @rpath), copies SwiftPM resource bundles (TelemetryDeck),
# repoints the rpath, and code-signs.
#
# One bundler for both local dev and CI — configured by env vars:
#   SIGN_IDENTITY      codesign identity. Default "-" (ad-hoc; launches locally).
#                      In CI pass your "Developer ID Application: …" identity.
#   ENTITLEMENTS       entitlements plist, applied when signing for real.
#   UNIVERSAL          "1" → build a universal arm64 + x86_64 binary.
#   MARKETING_VERSION  override CFBundleShortVersionString (e.g. CI from a tag).
#
# Usage:   ./scripts/build-app.sh
# Output:  dist/World Cup Bar.app
#
set -euo pipefail

APP_NAME="World Cup Bar"
EXECUTABLE="WorldCupBar"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ARCH_FLAGS=()
[ "${UNIVERSAL:-0}" = "1" ] && ARCH_FLAGS=(--arch arm64 --arch x86_64)

echo "▸ Building release binary…"
swift build -c release ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"}
BIN="$(swift build -c release ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"} --show-bin-path)"

APP="dist/${APP_NAME}.app"
echo "▸ Assembling ${APP}…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"

# Executable
cp "$BIN/$EXECUTABLE" "$APP/Contents/MacOS/$EXECUTABLE"

# Info.plist — substitute the Xcode $(EXECUTABLE_NAME) variable; inject version if given
sed 's/[$](EXECUTABLE_NAME)/'"$EXECUTABLE"'/' Sources/WorldCupBar/Info.plist > "$APP/Contents/Info.plist"
if [ -n "${MARKETING_VERSION:-}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${MARKETING_VERSION}" "$APP/Contents/Info.plist"
fi
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Embed Sparkle.framework (binary links @rpath/Sparkle.framework/...)
[ -d "$BIN/Sparkle.framework" ] && cp -R "$BIN/Sparkle.framework" "$APP/Contents/Frameworks/"

# Embed SwiftPM resource bundles (e.g. TelemetryDeck) so Bundle.module resolves
for bundle in "$BIN"/*.bundle; do
    [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done

# Point the executable at the embedded frameworks
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/$EXECUTABLE" 2>/dev/null || true

# Code-sign. Ad-hoc for local launch; Developer ID + hardened runtime for distribution.
echo "▸ Code-signing (${SIGN_IDENTITY})…"
if [ "$SIGN_IDENTITY" = "-" ]; then
    codesign --force --deep --sign - "$APP"
else
    ENT_FLAG=()
    [ -n "${ENTITLEMENTS:-}" ] && ENT_FLAG=(--entitlements "$ENTITLEMENTS")
    codesign --force --deep --options runtime --timestamp ${ENT_FLAG[@]+"${ENT_FLAG[@]}"} --sign "$SIGN_IDENTITY" "$APP"
fi

echo ""
echo "✓ Built ${APP}"
[ "$SIGN_IDENTITY" = "-" ] && echo "  First launch: right-click → Open → Open (ad-hoc signed)."
