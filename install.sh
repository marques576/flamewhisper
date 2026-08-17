#!/bin/bash
set -euo pipefail

# Build the .app bundle (release) and install it into /Applications.

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_SOURCE="$PROJECT_DIR/dist/FlameWhisper.app"
APP_DEST="/Applications/FlameWhisper.app"

# 1. Build the .app bundle
echo "==> Building FlameWhisper.app..."
"$PROJECT_DIR/scripts/package-app.sh"

if [ ! -d "$APP_SOURCE" ]; then
    echo "ERROR: $APP_SOURCE not found after package-app.sh" >&2
    exit 1
fi

# 2. Quit a running instance before replacing it
if pgrep -x "FlameWhisper" >/dev/null; then
    echo "==> Quitting running FlameWhisper..."
    osascript -e 'tell application "FlameWhisper" to quit' 2>/dev/null || true
    sleep 1
fi

# 3. Install into /Applications
echo "==> Installing to $APP_DEST..."
rm -rf "$APP_DEST"
cp -R "$APP_SOURCE" "$APP_DEST"

echo "==> Done: $APP_DEST"

# 4. Reveal in Finder
open -R "$APP_DEST"