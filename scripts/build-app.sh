#!/usr/bin/env bash
#
# build-app.sh — assemble a double-clickable "World Cup Bar.app" from the
# SwiftPM build. `swift build` alone only produces a bare binary that Finder
# opens in Terminal; this wraps it in a proper macOS app bundle.
#
# It embeds Sparkle.framework (the binary links it via @rpath), copies any
# SwiftPM resource bundles (e.g. TelemetryDeck), repoints the rpath at the
# embedded frameworks, and ad-hoc code-signs so macOS will launch it locally.
#
# Usage:   ./scripts/build-app.sh
# Output:  dist/World Cup Bar.app
#
set -euo pipefail

APP_NAME="World Cup Bar"
EXECUTABLE="WorldCupBar"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "▸ Building release binary…"
swift build -c release
BIN="$(swift build -c release --show-bin-path)"

APP="dist/${APP_NAME}.app"
echo "▸ Assembling ${APP}…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"

# Executable
cp "$BIN/$EXECUTABLE" "$APP/Contents/MacOS/$EXECUTABLE"

# Info.plist — substitute the Xcode $(EXECUTABLE_NAME) variable SwiftPM doesn't expand
sed 's/[$](EXECUTABLE_NAME)/'"$EXECUTABLE"'/' Sources/WorldCupBar/Info.plist > "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Embed Sparkle.framework (binary links @rpath/Sparkle.framework/...)
if [ -d "$BIN/Sparkle.framework" ]; then
    cp -R "$BIN/Sparkle.framework" "$APP/Contents/Frameworks/"
fi

# Embed SwiftPM resource bundles (e.g. TelemetryDeck) so Bundle.module resolves
for bundle in "$BIN"/*.bundle; do
    [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done

# Point the executable at the embedded frameworks
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/$EXECUTABLE" 2>/dev/null || true

# Ad-hoc code-sign (nested frameworks/XPC included) so Gatekeeper allows a local launch
echo "▸ Code-signing (ad-hoc)…"
codesign --force --deep --sign - "$APP"

echo ""
echo "✓ Built ${APP}"
echo "  → Drag “${APP_NAME}.app” into your Applications folder."
echo "  → First launch: right-click the app → Open → Open."
