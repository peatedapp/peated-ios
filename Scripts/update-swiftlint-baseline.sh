#!/bin/bash

set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPOSITORY_ROOT"

SWIFTLINT_IMAGE="${SWIFTLINT_IMAGE:-ghcr.io/realm/swiftlint:0.65.1@sha256:f47e083201e47a136cda5ae847595bfe00226c444ca226fa74fa5dc648a9b057}"
GENERATED_BASELINE="$(mktemp "$REPOSITORY_ROOT/.swiftlint-baseline.generated.XXXXXX")"
NORMALIZED_BASELINE="$(mktemp "$REPOSITORY_ROOT/.swiftlint-baseline.normalized.XXXXXX")"

cleanup() {
    rm -f "$GENERATED_BASELINE" "$NORMALIZED_BASELINE"
}
trap cleanup EXIT

command -v docker >/dev/null 2>&1 || {
    echo 'error: docker is required to update the SwiftLint baseline' >&2
    exit 1
}

echo 'Regenerating the SwiftLint baseline with the pinned tool version...'
docker run --rm \
    --user "$(id -u):$(id -g)" \
    -v "$REPOSITORY_ROOT:/work" \
    -w /work \
    "$SWIFTLINT_IMAGE" \
    lint --config /work/.swiftlint.yml \
    --lenient \
    --no-cache \
    --write-baseline "/work/$(basename "$GENERATED_BASELINE")"

# SwiftLint serializes absolute file URLs. Store repository-relative paths so
# the committed baseline works in every local checkout and in CI containers.
sed 's#file:\\/\\/\\/work\\/##g' "$GENERATED_BASELINE" > "$NORMALIZED_BASELINE"
mv "$NORMALIZED_BASELINE" "$REPOSITORY_ROOT/.swiftlint-baseline.json"

echo 'Updated .swiftlint-baseline.json; review the diff before committing it.'
