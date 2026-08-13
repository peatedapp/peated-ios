#!/bin/bash

set -euo pipefail

REQUIRED_TOOL="${1:-xcodebuild}"

if [ "$(uname -s)" != 'Darwin' ]; then
    echo "error: $REQUIRED_TOOL verification requires macOS" >&2
    exit 1
fi

if ! command -v "$REQUIRED_TOOL" >/dev/null 2>&1; then
    echo "error: $REQUIRED_TOOL is unavailable; install or select Xcode first" >&2
    exit 1
fi
