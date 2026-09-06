#!/bin/bash

set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPOSITORY_ROOT"

printf 'Host: %s %s\n' "$(uname -s)" "$(uname -m)"
printf 'Repository: %s\n\n' "$REPOSITORY_ROOT"

EXPECTED_XCODE_VERSION="$(tr -d '[:space:]' < .xcode-version)"

tool_status() {
    local tool="$1"

    if command -v "$tool" >/dev/null 2>&1; then
        printf '  %-12s %s\n' "$tool" "$(command -v "$tool")"
    else
        printf '  %-12s %s\n' "$tool" 'unavailable'
    fi
}

echo 'Tools:'
for tool in git make brew docker jq asc actionlint swift swiftformat swiftlint shellcheck xcodebuild xcrun; do
    tool_status "$tool"
done

echo
printf 'Expected Xcode: %s\n' "$EXPECTED_XCODE_VERSION"
if command -v xcodebuild >/dev/null 2>&1; then
    ACTUAL_XCODE_VERSION="$(xcodebuild -version | awk 'NR == 1 { print $2 }')"
    if [ "$ACTUAL_XCODE_VERSION" = "$EXPECTED_XCODE_VERSION" ]; then
        printf 'Selected Xcode: %s\n' "$ACTUAL_XCODE_VERSION"
    else
        printf 'Selected Xcode: %s (expected %s)\n' "$ACTUAL_XCODE_VERSION" "$EXPECTED_XCODE_VERSION"
    fi
fi

echo
echo 'Available verification:'
echo '  make check         portable repository checks'

if command -v swiftformat >/dev/null 2>&1 && \
   command -v swiftlint >/dev/null 2>&1 && \
   command -v shellcheck >/dev/null 2>&1; then
    echo '  make lint          available'
else
    echo '  make lint          unavailable (missing one or more lint tools)'
fi

if command -v docker >/dev/null 2>&1; then
    echo '  make lint-docker   available if the Docker daemon is running'
else
    echo '  make lint-docker   unavailable (Docker is missing)'
fi

if command -v swift >/dev/null 2>&1; then
    echo '  make test-api      available'
else
    echo '  make test-api      unavailable (Swift is missing)'
fi

if [ "$(uname -s)" = 'Darwin' ] && command -v xcodebuild >/dev/null 2>&1; then
    echo '  make verify        available'
else
    echo '  make verify        unavailable (requires macOS and Xcode)'
fi
