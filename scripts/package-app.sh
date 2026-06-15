#!/bin/bash
set -euo pipefail

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_DIR/dist}"
APP_NAME="FlameWhisper"
BUNDLE_NAME="$APP_NAME.app"
INFO_PLIST="$PROJECT_DIR/Resources/Info.plist"
ENTITLEMENTS="$PROJECT_DIR/WhisperFlow.entitlements"
ARCHS="${ARCHS:-arm64}"

mkdir -p "$OUTPUT_DIR"

# Build
echo "==> Building for archs: $ARCHS"

BINARIES=()
for arch in $ARCHS; do
    echo "  -> Building $arch..."
    swift build -c release --arch "$arch" --build-path "$BUILD_DIR"
    bin="$BUILD_DIR/$arch-apple-macosx/release/$APP_NAME"
    if [ ! -f "$bin" ]; then
        echo "ERROR: build product not found: $bin"
        exit 1
    fi
    BINARIES+=("$bin")
done

# Assemble .app bundle
APP_DIR="$OUTPUT_DIR/$BUNDLE_NAME"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

if [ ${#BINARIES[@]} -gt 1 ]; then
    echo "==> Creating universal binary..."
    lipo -create "${BINARIES[@]}" -output "$APP_DIR/Contents/MacOS/$APP_NAME"
else
    cp "${BINARIES[0]}" "$APP_DIR/Contents/MacOS/$APP_NAME"
fi

chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$INFO_PLIST" "$APP_DIR/Contents/Info.plist"
cp "$ENTITLEMENTS" "$APP_DIR/Contents/Resources/"

# Code-sign (ad-hoc)
echo "==> Code-signing (ad-hoc)..."
codesign --force --deep --sign - \
    --entitlements "$ENTITLEMENTS" \
    --options runtime \
    "$APP_DIR"

echo "==> Done: $APP_DIR"

# Optionally zip
if [ "${ZIP:-1}" = "1" ]; then
    ZIP_FILE="$OUTPUT_DIR/$APP_NAME.zip"
    rm -f "$ZIP_FILE"
    ditto -c -k --keepParent "$APP_DIR" "$ZIP_FILE"
    echo "==> Archive: $ZIP_FILE"
fi

echo ""
echo "To distribute: share $APP_NAME.zip"
echo "Users: unzip, drag to /Applications, right-click → Open (first launch only)"
