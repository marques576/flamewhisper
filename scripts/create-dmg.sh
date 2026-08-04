#!/bin/bash
set -euo pipefail

# Create the classic macOS drag-to-Applications DMG installer.
# Requires macOS (hdiutil, dmgbuild via pip in an isolated venv).

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_DIR/dist}"
DMG_PATH="$OUTPUT_DIR/FlameWhisper.dmg"
SETTINGS="$PROJECT_DIR/packaging/macos/dmgbuild-settings.py"
export DMGBUILD_SETTINGS_DIR="$(dirname "$SETTINGS")"

mkdir -p "$OUTPUT_DIR"

# 1. Build the .app bundle (also produces FlameWhisper.zip)
echo "==> Building .app bundle..."
"$PROJECT_DIR/scripts/package-app.sh"

if [ ! -d "$OUTPUT_DIR/FlameWhisper.app" ]; then
    echo "ERROR: FlameWhisper.app not found after package-app.sh" >&2
    exit 1
fi

# 2. dmgbuild in an isolated venv (macOS system python may be read-only)
echo "==> Setting up dmgbuild..."
VENV_DIR="$(mktemp -d)/dmgbuild-venv"
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --quiet --disable-pip-version-check dmgbuild

# 3. Assemble the DMG
echo "==> Creating $DMG_PATH..."
rm -f "$DMG_PATH"
"$VENV_DIR/bin/python" -m dmgbuild \
    --settings "$SETTINGS" \
    "FlameWhisper" "$DMG_PATH"

echo "==> Done: $DMG_PATH"
ls -lh "$DMG_PATH"

echo ""
echo "To distribute: upload FlameWhisper.dmg to GitHub Releases."
echo "Users: open the DMG, drag FlameWhisper.app into the Applications folder link."
