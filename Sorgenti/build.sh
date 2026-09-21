#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/LidMotion.app"
CACHE_DIR="/tmp/swift-cache"

echo "=== Compilazione LidMotion ==="
mkdir -p "$BUILD_DIR"
mkdir -p "$CACHE_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

SOURCES=(
    "$SCRIPT_DIR/Sources/main.swift"
    "$SCRIPT_DIR/Sources/AppDelegate.swift"
    "$SCRIPT_DIR/Sources/Settings/PreferencesManager.swift"
    "$SCRIPT_DIR/Sources/Settings/SettingsWindowController.swift"
    "$SCRIPT_DIR/Sources/Sensor/LidAngleSensor.swift"
    "$SCRIPT_DIR/Sources/Capture/ScreenCapturer.swift"
    "$SCRIPT_DIR/Sources/Overlay/DuoOverlayWindow.swift"
    "$SCRIPT_DIR/Sources/Overlay/FoldShader.swift"
    "$SCRIPT_DIR/Sources/Overlay/FoldController.swift"
    "$SCRIPT_DIR/Sources/Overlay/DuoRenderer.swift"
    "$SCRIPT_DIR/Sources/UI/AppState.swift"
    "$SCRIPT_DIR/Sources/UI/SettingsView.swift"
    "$SCRIPT_DIR/Sources/UI/OnboardingView.swift"
)

echo "Compilazione sorgenti Swift..."
swiftc \
    -module-cache-path "$CACHE_DIR" \
    -O \
    -target arm64-apple-macosx14.0 \
    -framework AppKit \
    -framework IOKit \
    -framework ScreenCaptureKit \
    -framework QuartzCore \
    -framework CoreGraphics \
    -framework CoreMedia \
    -framework CoreVideo \
    -framework Metal \
    -framework MetalKit \
    -framework MetalPerformanceShaders \
    -framework Foundation \
    -framework SwiftUI \
    -framework Combine \
    -o "$APP_BUNDLE/Contents/MacOS/LidMotion" \
    "${SOURCES[@]}"

echo "Copia Info.plist e assets..."
cp "$SCRIPT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
if [ -f "$SCRIPT_DIR/Resources/AppIcon.icns" ]; then
    cp "$SCRIPT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo "Rimozione attributi estesi..."
xattr -cr "$APP_BUNDLE"

echo "Firma dell'applicazione con firma ad-hoc..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Verifica firma..."
codesign --verify --verbose "$APP_BUNDLE"

echo "=== Compilazione completata con successo! ==="
rm -rf "$ROOT_DIR/LidMotion.app"
cp -R "$APP_BUNDLE" "$ROOT_DIR/LidMotion.app"
echo "App pronta in: LidMotion/LidMotion.app"
