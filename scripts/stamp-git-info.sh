#!/bin/sh
# Writes a DisplayVersion key into the built Debug app's Info.plist set to
# `git describe`, so the Settings footer shows the exact local build. Release
# builds skip this — the footer then falls back to CFBundleShortVersionString
# (the marketing version CI injects from the tag). Never fails the build.
set -u

# Only the local Debug build needs git detail; release builds show the marketing
# version (CFBundleShortVersionString).
[ "${CONFIGURATION:-}" = "Debug" ] || exit 0

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
[ -f "${PLIST}" ] || { echo "warning: Info.plist not found at ${PLIST}; skipping"; exit 0; }

# Restrict to the git-describe character set so the value can't alter the
# PlistBuddy command string below; strip the leading "v" (the footer re-adds it).
DESCRIBE="$(git -C "${SRCROOT}" describe --tags --always --abbrev=7 2>/dev/null | tr -cd 'A-Za-z0-9._+/-')"
DESCRIBE="${DESCRIBE#v}"
[ -n "${DESCRIBE}" ] || exit 0

# Append -dirty for uncommitted changes to build inputs (Sources, project.yml).
# Untracked docs and gitignored artifacts (.build, dist, *.xcodeproj) don't count.
if [ -n "$(git -C "${SRCROOT}" status --porcelain -- Sources project.yml 2>/dev/null)" ]; then
  DESCRIBE="${DESCRIBE}-dirty"
fi

/usr/libexec/PlistBuddy -c "Add :DisplayVersion string ${DESCRIBE}" "${PLIST}" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :DisplayVersion ${DESCRIBE}" "${PLIST}" 2>/dev/null || true

echo "Set DisplayVersion=${DESCRIBE} in ${PLIST}"
