#!/usr/bin/env bash

set -euo pipefail

# ==================================================
# PackageHub Unsigned IPA Builder
#
# Usage:
#
#   ./scripts/build_ipa.sh
#
#   ./scripts/build_ipa.sh --clean
#
#   ./scripts/build_ipa.sh --check
#
#   ./scripts/build_ipa.sh --clean --check
#
#   ./scripts/build_ipa.sh --cleanup-build
#
# Options:
#
#   --clean
#       Run flutter clean before building.
#
#   --check
#       Run flutter analyze + flutter test before building.
#
#   --cleanup-build
#       Remove ./build after IPA is successfully generated.
#
# Output:
#
#   dist/PackageHub-<version>-unsigned.ipa
#
# Example:
#
#   pubspec.yaml:
#     version: 1.0.3+7
#
#   output:
#     dist/PackageHub-1.0.3-7-unsigned.ipa
#
# ==================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CLEAN=false
CHECK=false
CLEANUP_BUILD=false

# --------------------------------------------------
# Parse arguments
# --------------------------------------------------

for arg in "$@"; do
  case "$arg" in
    --clean)
      CLEAN=true
      ;;
    --check)
      CHECK=true
      ;;
    --cleanup-build)
      CLEANUP_BUILD=true
      ;;
    *)
      echo "❌ Unknown argument: $arg"
      echo
      echo "Usage:"
      echo "  $0 [--clean] [--check] [--cleanup-build]"
      exit 1
      ;;
  esac
done

cd "$PROJECT_ROOT"

# --------------------------------------------------
# Basic checks
# --------------------------------------------------

if ! command -v flutter >/dev/null 2>&1; then
  echo "❌ Flutter not found in PATH."
  exit 1
fi

if ! command -v ditto >/dev/null 2>&1; then
  echo "❌ ditto not found."
  exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "❌ zip not found."
  exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "❌ unzip not found."
  exit 1
fi

if [[ ! -f "$PROJECT_ROOT/pubspec.yaml" ]]; then
  echo "❌ pubspec.yaml not found:"
  echo "   $PROJECT_ROOT/pubspec.yaml"
  exit 1
fi

if [[ ! -d "$PROJECT_ROOT/ios" ]]; then
  echo "❌ iOS project not found:"
  echo "   $PROJECT_ROOT/ios"
  exit 1
fi

# --------------------------------------------------
# Read version from pubspec.yaml
# --------------------------------------------------

VERSION="$(
  awk '
    /^version:[[:space:]]*/ {
      value = $0
      sub(/^version:[[:space:]]*/, "", value)
      gsub(/[[:space:]]/, "", value)
      print value
      exit
    }
  ' "$PROJECT_ROOT/pubspec.yaml"
)"

if [[ -z "$VERSION" ]]; then
  echo "⚠️  Unable to read version from pubspec.yaml."
  VERSION="unknown"
fi

# 1.0.3+7 -> 1.0.3-7
SAFE_VERSION="${VERSION//+/-}"

OUTPUT_DIR="$PROJECT_ROOT/dist"
OUTPUT_IPA="$OUTPUT_DIR/PackageHub-${SAFE_VERSION}-unsigned.ipa"

BUILD_APP="$PROJECT_ROOT/build/ios/iphoneos/Runner.app"

# --------------------------------------------------
# Temporary directory
# --------------------------------------------------

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/packagehub-ipa.XXXXXX")"

cleanup() {
  if [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}

trap cleanup EXIT INT TERM

# --------------------------------------------------
# Header
# --------------------------------------------------

echo
echo "📦 PackageHub IPA Builder"
echo "────────────────────────────────────────"
echo "Project : $PROJECT_ROOT"
echo "Version : $VERSION"
echo "Output  : $OUTPUT_IPA"
echo

# --------------------------------------------------
# Optional clean
# --------------------------------------------------

if [[ "$CLEAN" == true ]]; then
  echo "🧹 Cleaning Flutter build..."
  flutter clean
  echo
fi

# --------------------------------------------------
# Dependencies
# --------------------------------------------------

echo "📚 Resolving Flutter dependencies..."
flutter pub get

# --------------------------------------------------
# Optional checks
# --------------------------------------------------

if [[ "$CHECK" == true ]]; then
  echo
  echo "🔍 Running flutter analyze..."
  flutter analyze

  echo
  echo "🧪 Running flutter test..."
  flutter test
fi

# --------------------------------------------------
# Build unsigned Release app
# --------------------------------------------------

echo
echo "🔨 Building unsigned iOS Release..."
flutter build ios --release --no-codesign

# --------------------------------------------------
# Verify Runner.app
# --------------------------------------------------

if [[ ! -d "$BUILD_APP" ]]; then
  echo
  echo "❌ Runner.app was not generated:"
  echo "   $BUILD_APP"
  exit 1
fi

if [[ ! -f "$BUILD_APP/Info.plist" ]]; then
  echo
  echo "❌ Runner.app exists but Info.plist is missing:"
  echo "   $BUILD_APP/Info.plist"
  exit 1
fi

# --------------------------------------------------
# Prepare IPA
# --------------------------------------------------

echo
echo "📁 Creating IPA payload..."

mkdir -p "$TMP_DIR/Payload"
mkdir -p "$OUTPUT_DIR"

ditto \
  "$BUILD_APP" \
  "$TMP_DIR/Payload/Runner.app"

# Verify copied app before zipping
if [[ ! -f "$TMP_DIR/Payload/Runner.app/Info.plist" ]]; then
  echo
  echo "❌ Failed to copy Runner.app into Payload."
  exit 1
fi

rm -f "$OUTPUT_IPA"

(
  cd "$TMP_DIR"
  /usr/bin/zip -qry "$OUTPUT_IPA" Payload
)

# --------------------------------------------------
# Verify IPA exists
# --------------------------------------------------

if [[ ! -f "$OUTPUT_IPA" ]]; then
  echo
  echo "❌ IPA packaging failed."
  exit 1
fi

# --------------------------------------------------
# Validate IPA structure
#
# Do NOT pipe unzip directly into grep -q while
# using pipefail. grep -q may close the pipe early,
# causing unzip to receive SIGPIPE and creating a
# false validation failure.
# --------------------------------------------------

IPA_CONTENTS="$(/usr/bin/unzip -Z1 "$OUTPUT_IPA")"

if ! grep -Fxq "Payload/Runner.app/Info.plist" <<< "$IPA_CONTENTS"; then
  echo
  echo "❌ Invalid IPA structure."
  echo "   Payload/Runner.app/Info.plist not found."
  echo
  echo "IPA contents:"
  echo "$IPA_CONTENTS" | head -50
  exit 1
fi

# Verify executable also exists
if ! grep -Fxq "Payload/Runner.app/Runner" <<< "$IPA_CONTENTS"; then
  echo
  echo "❌ Invalid IPA structure."
  echo "   Payload/Runner.app/Runner executable not found."
  exit 1
fi

# --------------------------------------------------
# Result information
# --------------------------------------------------

IPA_SIZE="$(du -h "$OUTPUT_IPA" | awk '{print $1}')"

if command -v shasum >/dev/null 2>&1; then
  IPA_SHA256="$(shasum -a 256 "$OUTPUT_IPA" | awk '{print $1}')"
else
  IPA_SHA256="N/A"
fi

echo
echo "✅ IPA built successfully"
echo "────────────────────────────────────────"
echo "Version : $VERSION"
echo "File    : $OUTPUT_IPA"
echo "Size    : $IPA_SIZE"
echo "SHA256  : $IPA_SHA256"

# --------------------------------------------------
# Optional build cleanup
# --------------------------------------------------

if [[ "$CLEANUP_BUILD" == true ]]; then
  echo
  echo "🧹 Removing Flutter build directory..."
  rm -rf "$PROJECT_ROOT/build"
fi

echo
echo "Temporary build directory cleaned automatically."
echo
echo "Next:"
echo
echo "  PackageHub unsigned IPA"
echo "          ↓"
echo "  AirDrop / iCloud / GitHub Release"
echo "          ↓"
echo "  iPhone"
echo "          ↓"
echo "  全能签"
echo "          ↓"
echo "  重签名并安装"
echo