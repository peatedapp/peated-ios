#!/bin/bash

set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPOSITORY_ROOT"

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
    command -v swiftlint >/dev/null 2>&1 || {
        echo 'error: swiftlint is required to lint changed Swift files' >&2
        exit 1
    }
    command -v swiftformat >/dev/null 2>&1 || {
        echo 'error: swiftformat is required to lint changed Swift files' >&2
        exit 1
    }

    echo "Linting ${#swift_files[@]} changed Swift file(s)..."
    swiftlint lint --config .swiftlint.yml --baseline .swiftlint-baseline.json "${swift_files[@]}"
    swiftformat "${swift_files[@]}" --config .swiftformat --lint
else
    echo 'No changed hand-written Swift files to lint.'
fi

if [ "${#shell_files[@]}" -gt 0 ]; then
    command -v shellcheck >/dev/null 2>&1 || {
        echo 'error: shellcheck is required to lint changed shell files' >&2
        exit 1
    }

    echo "Linting ${#shell_files[@]} changed shell file(s)..."
    shellcheck "${shell_files[@]}"
else
    echo 'No changed shell files to lint.'
fi
