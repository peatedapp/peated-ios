#!/bin/bash

set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPOSITORY_ROOT"

echo 'Checking shell syntax...'
while IFS= read -r -d '' script; do
    bash -n "$script"
done < <(
    git ls-files -z '*.sh'
    git ls-files --others --exclude-standard -z -- '*.sh'
)

echo 'Checking JSON syntax...'
if command -v jq >/dev/null 2>&1; then
    while IFS= read -r -d '' document; do
        if ! jq empty "$document"; then
            echo "error: invalid JSON in $document" >&2
            exit 1
        fi
    done < <(
        git ls-files -z '*.json'
        git ls-files --others --exclude-standard -z -- '*.json'
    )
elif command -v plutil >/dev/null 2>&1; then
    while IFS= read -r -d '' document; do
        if ! plutil -lint "$document" >/dev/null; then
            echo "error: invalid JSON in $document" >&2
            exit 1
        fi
    done < <(
        git ls-files -z '*.json'
        git ls-files --others --exclude-standard -z -- '*.json'
    )
else
    echo 'error: JSON validation requires jq or plutil' >&2
    exit 1
fi

echo 'Checking agent instruction mirrors...'
for directory in . Peated PeatedCore PeatedAPI Scripts docs; do
    if ! cmp -s "$directory/AGENTS.md" "$directory/CLAUDE.md"; then
        echo "error: $directory/AGENTS.md and $directory/CLAUDE.md differ" >&2
        exit 1
    fi
done

echo 'Checking for unresolved merge markers...'
if git grep -n -E '^(<<<<<<<|>>>>>>>)' -- . >/dev/null; then
    git grep -n -E '^(<<<<<<<|>>>>>>>)' -- . >&2
    exit 1
fi

echo 'Checking changed lines for whitespace errors...'
git diff --check
git diff --cached --check

echo 'Repository checks passed.'
