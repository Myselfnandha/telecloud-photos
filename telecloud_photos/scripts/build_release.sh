#!/usr/bin/env bash
set -e

# ==============================================================================
# TeleCloud Photos — Production Release Packaging Script
# ==============================================================================

echo "=================================================="
echo "🚀 Building TeleCloud Photos Production Release"
echo "=================================================="

# 1. Check Flutter & Environment
echo ""
echo "🔍 [1/5] Checking Environment & Dependencies..."
flutter --version
flutter pub get

# 2. Static Code Analysis
echo ""
echo "🔬 [2/5] Running Static Analysis..."
flutter analyze
echo "✅ Analysis passed: 0 issues found."

# 3. Automated Test Suite
echo ""
echo "🧪 [3/5] Running Automated Test Suite..."
flutter test
echo "✅ All automated tests passed."

# 4. Universal Release APK
echo ""
echo "📦 [4/5] Building Universal Release APK..."
flutter build apk --release
echo "✅ Universal APK built: build/app/outputs/flutter-apk/app-release.apk"

# 5. Split-per-ABI APKs
echo ""
echo "📱 [5/5] Building Split-per-ABI Release APKs (arm64-v8a, armeabi-v7a, x86_64)..."
flutter build apk --split-per-abi --release

echo ""
echo "=================================================="
echo "🎉 Release Build Complete!"
echo "=================================================="
echo "Generated Release Artifacts:"
ls -lh build/app/outputs/flutter-apk/app-*.apk
echo "=================================================="
