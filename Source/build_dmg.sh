#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/LidMotion.app"
DMG_NAME="LidMotion_1.0.0.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
TEMP_DMG_DIR="$BUILD_DIR/dmg_temp"

echo "=== Creating DMG for LidMotion ==="

# Check if app exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: LidMotion.app not found. Run build.sh first."
    exit 1
fi

# Prepare temporary folder for DMG
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"
cp -R "$APP_BUNDLE" "$TEMP_DMG_DIR/"
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Remove existing DMG
rm -f "$DMG_PATH"

echo "Generating disk image..."
hdiutil create -volname "LidMotion" -srcfolder "$TEMP_DMG_DIR" -ov -format UDZO "$DMG_PATH"

# Cleanup
rm -rf "$TEMP_DMG_DIR"

echo "=== DMG ready: $DMG_PATH ==="
