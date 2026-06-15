#!/bin/sh
# Stamps the git short SHA and a "dirty" flag into the built app's Info.plist so
# the Settings footer can identify local builds. Runs as a post-build phase
# (after Info.plist processing, before code signing). Never fails the build.
set -u

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
SHA="$(git -C "${SRCROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"

# "dirty" = uncommitted changes to build inputs (Sources, project.yml).
# Untracked docs and gitignored artifacts (.build, dist, *.xcodeproj) don't count.
if [ -n "$(git -C "${SRCROOT}" status --porcelain -- Sources project.yml 2>/dev/null)" ]; then
  DIRTY=true
else
  DIRTY=false
fi

if [ ! -f "${PLIST}" ]; then
  echo "warning: Info.plist not found at ${PLIST}; skipping git stamp"
  exit 0
fi

/usr/libexec/PlistBuddy -c "Add :GitSHA string ${SHA}" "${PLIST}" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :GitSHA ${SHA}" "${PLIST}" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :GitDirty bool ${DIRTY}" "${PLIST}" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :GitDirty ${DIRTY}" "${PLIST}" 2>/dev/null || true

echo "Stamped GitSHA=${SHA} GitDirty=${DIRTY} into ${PLIST}"
