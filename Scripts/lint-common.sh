# shellcheck shell=bash
# Shared lint settings for the Makefile, the pre-commit hook, and the lint
# scripts. Source this file; do not run it.
#
# The image tags are the pinned tool versions. CI lints with these images, so
# native tools are used only when their versions match the tags exactly.

SWIFTFORMAT_IMAGE="${SWIFTFORMAT_IMAGE:-ghcr.io/nicklockwood/swiftformat:0.63.0@sha256:cb50a33496b4f5123b99241437f24f154a68085398cfda1412ed3b6bab9c02ec}"
SWIFTLINT_IMAGE="${SWIFTLINT_IMAGE:-ghcr.io/realm/swiftlint:0.65.1@sha256:f47e083201e47a136cda5ae847595bfe00226c444ca226fa74fa5dc648a9b057}"
SHELLCHECK_IMAGE="${SHELLCHECK_IMAGE:-koalaman/shellcheck:v0.11.0}"

# Prints the tag of an image reference such as `name:1.2.3@sha256:...`.
image_version() {
    local reference="${1%%@*}"
    printf '%s\n' "${reference##*:}"
}

# Succeeds when native swiftformat and swiftlint match the pinned images.
# Prints a note to stderr when an installed tool has another version.
native_swift_lint_tools_match() {
    local expected actual

    command -v swiftformat >/dev/null 2>&1 || return 1
    command -v swiftlint >/dev/null 2>&1 || return 1

    expected="$(image_version "$SWIFTFORMAT_IMAGE")"
    actual="$(swiftformat --version)"
    if [ "$actual" != "$expected" ]; then
        echo "note: native SwiftFormat is $actual; CI uses $expected" >&2
        return 1
    fi

    expected="$(image_version "$SWIFTLINT_IMAGE")"
    actual="$(swiftlint version)"
    if [ "$actual" != "$expected" ]; then
        echo "note: native SwiftLint is $actual; CI uses $expected" >&2
        return 1
    fi
}

docker_is_running() {
    command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

# Prints NUL-separated changed files that match a pathspec pattern.
changed_files() {
    local pattern="$1" file

    if [ -n "${LINT_BASE_REF:-}" ]; then
        git diff --name-only --diff-filter=ACMR -z "$LINT_BASE_REF...HEAD" -- "$pattern"
        return
    fi

    if git rev-parse -q --verify MERGE_HEAD >/dev/null; then
        # A merge brings in files that already passed CI on the merged branch.
        # Skip files that match that branch, so only this side's changes,
        # combined edits, and conflict resolutions are checked.
        git diff --name-only --diff-filter=ACMR -z HEAD -- "$pattern" |
            while IFS= read -r -d '' file; do
                git diff --quiet MERGE_HEAD -- "$file" || printf '%s\0' "$file"
            done
    else
        git diff --name-only --diff-filter=ACMR -z HEAD -- "$pattern"
    fi
    git ls-files --others --exclude-standard -z -- "$pattern"
}
