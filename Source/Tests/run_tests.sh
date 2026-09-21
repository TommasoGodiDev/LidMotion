#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CACHE_DIR="/tmp/swift-cache"
TEST_BINARY="/tmp/lidmotion_tests"

mkdir -p "$CACHE_DIR"

echo "=== Compilazione LidMotion Automated Test Suite ==="
swiftc \
    -module-cache-path "$CACHE_DIR" \
    -target arm64-apple-macosx14.0 \
    -O \
    -framework AppKit \
    -framework Metal \
    -framework MetalKit \
    -framework MetalPerformanceShaders \
    -framework QuartzCore \
    -framework CoreGraphics \
    -framework CoreVideo \
    -framework Foundation \
    -o "$TEST_BINARY" \
    "$PROJECT_DIR/Sources/Settings/PreferencesManager.swift" \
    "$PROJECT_DIR/Sources/Overlay/FoldShader.swift" \
    "$PROJECT_DIR/Sources/Overlay/DuoRenderer.swift" \
    "$SCRIPT_DIR/Harness/TestTypes.swift" \
    "$SCRIPT_DIR/Harness/TestHarness.swift" \
    "$SCRIPT_DIR/Suites/Tier1_FeatureCoverageTests.swift" \
    "$SCRIPT_DIR/Suites/Tier2_BoundaryCornerTests.swift" \
    "$SCRIPT_DIR/Suites/Tier3_CrossFeatureTests.swift" \
    "$SCRIPT_DIR/Suites/Tier4_AcceptanceScenarioTests.swift" \
    "$SCRIPT_DIR/MainTestRunner.swift"

echo "=== Esecuzione LidMotion Automated Test Suite ==="
"$TEST_BINARY"
TEST_EXIT_CODE=$?

exit $TEST_EXIT_CODE
