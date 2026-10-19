#!/bin/bash

set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPOSITORY_ROOT"

# shellcheck source=Scripts/lint-common.sh
. "$REPOSITORY_ROOT/Scripts/lint-common.sh"

if [ -n "${LINT_BASE_REF:-}" ]; then
    if ! git rev-parse --verify "${LINT_BASE_REF}^{commit}" >/dev/null 2>&1; then
        echo "error: LINT_BASE_REF does not resolve to a commit: $LINT_BASE_REF" >&2
        exit 1
    fi
fi

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

if [ "${#swift_files[@]}" -gt 0 ] && ! native_swift_lint_tools_match; then
    if docker_is_running; then
        echo 'Linting with the pinned Docker images instead.'
        exec "$REPOSITORY_ROOT/Scripts/lint-changed-docker.sh"
    fi

    printf 'error: changed Swift files need SwiftFormat %s and SwiftLint %s, or a running Docker daemon\n' \
        "$(image_version "$SWIFTFORMAT_IMAGE")" "$(image_version "$SWIFTLINT_IMAGE")" >&2
    exit 1
fi

if [ "${#swift_files[@]}" -gt 0 ]; then
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
