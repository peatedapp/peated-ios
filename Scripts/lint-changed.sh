#!/bin/bash

set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPOSITORY_ROOT"

swift_files=()
while IFS= read -r -d '' file; do
    case "$file" in
        PeatedAPI/Sources/PeatedAPI/Generated/*)
            ;;
        *)
            swift_files+=("$file")
            ;;
    esac
done < <(
    git diff --name-only --diff-filter=ACMR -z HEAD -- '*.swift'
    git ls-files --others --exclude-standard -z -- '*.swift'
)

shell_files=()
while IFS= read -r -d '' file; do
    shell_files+=("$file")
done < <(
    git diff --name-only --diff-filter=ACMR -z HEAD -- '*.sh'
    git ls-files --others --exclude-standard -z -- '*.sh'
)

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
    swiftlint lint --config .swiftlint.yml "${swift_files[@]}"
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
