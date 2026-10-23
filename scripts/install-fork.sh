#!/bin/bash
# Installs the Coucou built from a fork's main (.github/workflows/fork-build.yml)
# in /Applications, in place of the one there.
#   bash scripts/install-fork.sh            # Fahmiady11/coucou
#   COUCOU_REPO=you/coucou bash scripts/install-fork.sh
set -euo pipefail

REPO="${COUCOU_REPO:-Fahmiady11/coucou}"
URL="https://github.com/${REPO}/releases/download/fork-latest/Coucou.zip"
BUNDLE_ID="fr.louisraille.NotchBuddy"
TARGET="/Applications/Coucou.app"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "Downloading ${URL}..."
curl -fL --progress-bar -o "$WORK/Coucou.zip" "$URL"
ditto -x -k "$WORK/Coucou.zip" "$WORK"

APP="$WORK/Coucou.app"
FOUND=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Contents/Info.plist")
if [ "$FOUND" != "$BUNDLE_ID" ]; then
  echo "Not Coucou (${FOUND}): nothing installed." >&2
  exit 1
fi
codesign --verify --deep --strict "$APP"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")

echo "Quitting Coucou..."
osascript -e "tell application id \"${BUNDLE_ID}\" to quit" >/dev/null 2>&1 || true
for _ in 1 2 3 4 5; do pgrep -x Coucou >/dev/null || break; sleep 1; done
pkill -x Coucou 2>/dev/null || true

echo "Installing Coucou ${VERSION} in ${TARGET}..."
rm -rf "$TARGET"
ditto "$APP" "$TARGET"
# Built by your own CI and fetched by you: no Gatekeeper prompt for it.
xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true

open "$TARGET"
echo "Coucou ${VERSION} from ${REPO} is running."
