#!/bin/bash

set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPOSITORY_ROOT"

SWIFTFORMAT_IMAGE="${SWIFTFORMAT_IMAGE:-ghcr.io/nicklockwood/swiftformat:0.62.1}"
SWIFTLINT_IMAGE="${SWIFTLINT_IMAGE:-ghcr.io/realm/swiftlint:0.65.0}"
SHELLCHECK_IMAGE="${SHELLCHECK_IMAGE:-koalaman/shellcheck:v0.11.0}"

command -v docker >/dev/null 2>&1 || {
    echo 'error: docker is required for containerized linting' >&2
    exit 1
}

if [ -n "${LINT_BASE_REF:-}" ]; then
    if ! git rev-parse --verify "${LINT_BASE_REF}^{commit}" >/dev/null 2>&1; then
        echo "error: LINT_BASE_REF does not resolve to a commit: $LINT_BASE_REF" >&2
        exit 1
    fi
fi

changed_files() {
    local pattern="$1"

    if [ -n "${LINT_BASE_REF:-}" ]; then
        git diff --name-only --diff-filter=ACMR -z "$LINT_BASE_REF...HEAD" -- "$pattern"
    else
        git diff --name-only --diff-filter=ACMR -z HEAD -- "$pattern"
        git ls-files --others --exclude-standard -z -- "$pattern"
    fi
}

swift_files=()
while IFS= read -r -d '' file; do
    case "$file" in
        PeatedAPI/Sources/PeatedAPI/Generated/*)
            ;;
        *)
            swift_files+=("$file")
            ;;
    esac
done < <(changed_files '*.swift')

shell_files=()
while IFS= read -r -d '' file; do
    shell_files+=("$file")
done < <(changed_files '*.sh')

if [ "${#swift_files[@]}" -gt 0 ]; then
    echo "Linting ${#swift_files[@]} changed Swift file(s) with Docker..."
    docker run --rm \
        -v "$REPOSITORY_ROOT:/work:ro" \
        -w /work \
        "$SWIFTLINT_IMAGE" \
        lint --config /work/.swiftlint.yml "${swift_files[@]}"
    docker run --rm \
        -v "$REPOSITORY_ROOT:/work:ro" \
        -w /work \
        "$SWIFTFORMAT_IMAGE" \
        "${swift_files[@]}" --config /work/.swiftformat --lint
else
    echo 'No changed hand-written Swift files to lint.'
fi

if [ "${#shell_files[@]}" -gt 0 ]; then
    echo "Linting ${#shell_files[@]} changed shell file(s) with Docker..."
    docker run --rm \
        -v "$REPOSITORY_ROOT:/work:ro" \
        -w /work \
        "$SHELLCHECK_IMAGE" \
        "${shell_files[@]}"
else
    echo 'No changed shell files to lint.'
fi
