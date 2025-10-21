#!/usr/bin/env bash
set -euo pipefail

if [[ "${SKIP_NIGHTLY_CHECK:-}" == "1" ]]; then
  exit 0
fi

if [[ $(uname) != "Darwin" ]]; then
  echo "Nightly roll-up requires macOS with Xcode installed." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/RealLifeLingo/RealLifeLingo.xcodeproj"
SCHEME="RealLifeLingo"
DESTINATION=${DESTINATION:-"platform=iOS Simulator,name=iPhone 15"}
TEST_TARGET="RealLifeLingoTests/NightlyAutomationTests"

if [[ ! -d "$PROJECT" ]]; then
  echo "error: Expected Xcode project at $PROJECT. Open the repository in Xcode and create the project to continue." >&2
  exit 2
fi

set -x
xcrun xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -only-testing "$TEST_TARGET" \
  test
