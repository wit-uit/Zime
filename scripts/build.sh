#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
xcodebuild -project "$TASK_ROOT/Zime.xcodeproj" -scheme Zime \
    -configuration Debug -destination 'platform=macOS' \
    -derivedDataPath "$TASK_ROOT/build" CODE_SIGNING_ALLOWED=NO build "$@"
