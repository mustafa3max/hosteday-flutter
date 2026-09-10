#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
dart format lib test example/lib example/test
flutter analyze
flutter test
(
  cd example
  flutter pub get
  flutter analyze
  flutter test
)
