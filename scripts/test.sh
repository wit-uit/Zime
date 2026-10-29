#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/zime-tests.XXXXXX")"
trap 'rm -rf "$TASK_TEST_DIR"' EXIT
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
xcrun swiftc -parse-as-library "$TASK_ROOT/Zime/TimerEngine.swift" \
    "$TASK_ROOT/Tests/TimerEngineTests.swift" -o "$TASK_TEST_DIR/TimerEngineTests"
"$TASK_TEST_DIR/TimerEngineTests"
