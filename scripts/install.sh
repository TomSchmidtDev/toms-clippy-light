#!/usr/bin/env bash
# Helper script that removes the macOS quarantine flag from the unsigned
# TomsClippyLight.app after the user moves it to /Applications.

set -euo pipefail

APP_PATH="${1:-/Applications/TomsClippyLight.app}"

if [[ ! -d "$APP_PATH" ]]; then
    echo "Error: $APP_PATH not found. Pass the full path to TomsClippyLight.app as first argument."
    exit 1
fi

echo "Removing quarantine attribute from $APP_PATH ..."
xattr -d com.apple.quarantine "$APP_PATH"
echo "Done. You can now open the app."
