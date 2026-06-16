#!/usr/bin/env bash
#
# make-dmg.sh — package a built .app into a mount-and-drag-to-Applications DMG.
#
# Usage:   ./scripts/make-dmg.sh <path-to-.app> [output-dir]
# Example: ./scripts/make-dmg.sh build/export/WorldCupBar.app dist
# Output:  <output-dir>/<AppName>.dmg
#
# Icon layout is best-effort (needs a Finder/GUI session); the DMG is valid
# either way — it always shows the app next to an Applications shortcut.
#
set -euo pipefail

APP="${1:?usage: make-dmg.sh <path-to-.app> [output-dir]}"
OUT_DIR="${2:-dist}"
[ -d "$APP" ] || { echo "✗ $APP not found"; exit 1; }

PLIST="$APP/Contents/Info.plist"
NAME="$(basename "$APP" .app)"
VOL_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$PLIST" 2>/dev/null || echo "$NAME")"

mkdir -p "$OUT_DIR"
DMG="${OUT_DIR}/${NAME}.dmg"
RW_DMG="$(mktemp -u).dmg"
MOUNT_DIR="/Volumes/${VOL_NAME}"
hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true

echo "▸ Staging ${NAME}.app + Applications shortcut…"
STAGING="$(mktemp -d)"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "▸ Creating writable image…"
hdiutil create -srcfolder "$STAGING" -volname "$VOL_NAME" -fs HFS+ -format UDRW -ov "$RW_DMG" >/dev/null
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
        set position of item "${NAME}.app" of container window to {140, 175}
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
echo "  Double-click → drag “${NAME}.app” onto the Applications shortcut."
