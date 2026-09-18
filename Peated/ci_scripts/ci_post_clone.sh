#!/bin/bash

# Xcode Cloud uses the reviewed Swift package graph committed with the app.

set -euo pipefail

REPOSITORY_ROOT="$(git rev-parse --show-toplevel)"
LOCKFILE="$REPOSITORY_ROOT/Peated/Peated.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

if [ ! -f "$LOCKFILE" ]; then
    echo "error: missing app Package.resolved at $LOCKFILE" >&2
    exit 1
fi

echo 'Using the committed Swift package resolution.'
