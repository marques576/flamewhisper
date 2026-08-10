#!/bin/bash
set -euo pipefail

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_DIR/dist}"
APP_NAME="FlameWhisper"
BUNDLE_NAME="$APP_NAME.app"
INFO_PLIST="$PROJECT_DIR/Resources/Info.plist"
ENTITLEMENTS="$PROJECT_DIR/FlameWhisper.entitlements"
ARCHS="${ARCHS:-arm64}"
SWIFTPM_CACHE_DIR="${SWIFTPM_CACHE_DIR:-$BUILD_DIR/swiftpm-cache}"
CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$BUILD_DIR/clang-module-cache}"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$SWIFTPM_CACHE_DIR" "$CLANG_MODULE_CACHE_PATH"
export CLANG_MODULE_CACHE_PATH

# Build
echo "==> Building for archs: $ARCHS"

BINARIES=()
for arch in $ARCHS; do
    echo "  -> Building $arch..."
    swift build \
        -c release \
        --arch "$arch" \
        --build-path "$BUILD_DIR" \
        --cache-path "$SWIFTPM_CACHE_DIR"
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
    "$APP_DIR"

echo "==> Done: $APP_DIR"
