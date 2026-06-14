#!/usr/bin/env bash
#
# make-dmg.sh — package "World Cup Bar.app" into a mount-and-drag-to-Applications
# disk image. Run scripts/build-app.sh first (it produces dist/World Cup Bar.app).
#
# Output: dist/World Cup Bar-<version>.dmg
#
# The DMG shows the app next to an Applications shortcut so the user just drags
# one onto the other — the classic macOS install. Icon layout is best-effort
# (needs a Finder/GUI session); the DMG is valid either way.
#
set -euo pipefail

APP_NAME="World Cup Bar"
VOL_NAME="World Cup Bar"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP="dist/${APP_NAME}.app"
[ -d "$APP" ] || { echo "✗ $APP not found — run scripts/build-app.sh first"; exit 1; }

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
DMG="dist/WorldCupBar-${VERSION}.dmg"
RW_DMG="$(mktemp -u).dmg"
MOUNT_DIR="/Volumes/${VOL_NAME}"

# Clean up any stale mount from a previous run
hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true

echo "▸ Staging app + Applications shortcut…"
STAGING="$(mktemp -d)"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "▸ Creating writable image…"
hdiutil create -srcfolder "$STAGING" -volname "$VOL_NAME" -fs HFS+ \
    -format UDRW -ov "$RW_DMG" >/dev/null
rm -rf "$STAGING"

echo "▸ Laying out the window…"
hdiutil attach "$RW_DMG" -noautoopen -quiet
osascript <<OSA 2>/dev/null || echo "  (skipped icon layout — no Finder session; DMG still valid)"
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 720, 470}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 120
        set position of item "${APP_NAME}.app" of container window to {140, 175}
        set position of item "Applications" of container window to {380, 175}
        update without registering applications
        delay 1
        close
    end tell
end tell
OSA
sync
hdiutil detach "$MOUNT_DIR" -quiet

echo "▸ Compressing…"
rm -f "$DMG"
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null
rm -f "$RW_DMG"

echo ""
echo "✓ Built $DMG"
echo "  Double-click it → drag “${APP_NAME}.app” onto the Applications shortcut."
