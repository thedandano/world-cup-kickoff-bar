#!/bin/sh
# Stamps `git describe` output and a "dirty" flag into the built app's Info.plist
# so the Settings footer can show the version (e.g. v1.1.1-5-g5450215). Runs as a
# post-build phase (after Info.plist processing, before code signing). Never
# fails the build.
set -u

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
# Restrict to the git-describe character set so the value can't alter the
# PlistBuddy command string below (defense-in-depth: the expansion is already
# double-quoted and git refnames can't contain shell metacharacters).
DESCRIBE="$(git -C "${SRCROOT}" describe --tags --always --abbrev=7 2>/dev/null | tr -cd 'A-Za-z0-9._+/-')"
[ -n "${DESCRIBE}" ] || DESCRIBE="unknown"

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

/usr/libexec/PlistBuddy -c "Add :GitDescribe string ${DESCRIBE}" "${PLIST}" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :GitDescribe ${DESCRIBE}" "${PLIST}" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :GitDirty bool ${DIRTY}" "${PLIST}" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :GitDirty ${DIRTY}" "${PLIST}" 2>/dev/null || true

echo "Stamped GitDescribe=${DESCRIBE} GitDirty=${DIRTY} into ${PLIST}"
