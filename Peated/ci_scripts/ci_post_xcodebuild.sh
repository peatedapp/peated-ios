#!/bin/bash

# Xcode Cloud runs this after each xcodebuild action. After a release archive it
# uploads debug symbols to Sentry so crashes and app hangs show readable
# stack traces, and records the release so events link to this build.
#
# Set SENTRY_AUTH_TOKEN in the Xcode Cloud workflow environment. The token needs
# the project:releases and project:write scopes for the peated/ios project.

set -euo pipefail

if [ "${CI_XCODEBUILD_ACTION:-}" != 'archive' ]; then
    exit 0
fi

if [ -z "${SENTRY_AUTH_TOKEN:-}" ]; then
    echo 'warning: SENTRY_AUTH_TOKEN is not set; skipping Sentry symbol upload' >&2
    exit 0
fi

SENTRY_CLI_VERSION='3.8.0'
SENTRY_CLI_SHA256='2c26914636c47ab9bf9e710484ad7b44d371cbec8bd29cafb36b3cf877bf4285'
SENTRY_CLI_URL="https://downloads.sentry-cdn.com/sentry-cli/${SENTRY_CLI_VERSION}/sentry-cli-Darwin-universal"

export SENTRY_ORG='peated'
export SENTRY_PROJECT='ios'

install_dir="$(mktemp -d)"
sentry_cli="${install_dir}/sentry-cli"

echo "Installing sentry-cli ${SENTRY_CLI_VERSION}..."
curl --fail --location --silent --show-error --output "$sentry_cli" "$SENTRY_CLI_URL"
echo "${SENTRY_CLI_SHA256}  ${sentry_cli}" | shasum --algorithm 256 --check --status
chmod +x "$sentry_cli"

archive_plist="${CI_ARCHIVE_PATH}/Info.plist"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleIdentifier' "$archive_plist")"
short_version="$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleShortVersionString' "$archive_plist")"
build_number="$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleVersion' "$archive_plist")"

# Matches the release name sentry-cocoa reports by default.
release="${bundle_id}@${short_version}+${build_number}"

echo "Uploading debug symbols for ${release}..."
"$sentry_cli" debug-files upload --include-sources "${CI_ARCHIVE_PATH}/dSYMs"

echo "Recording release ${release}..."
"$sentry_cli" releases new "$release"
if ! "$sentry_cli" releases set-commits --local --ignore-missing "$release"; then
    echo 'warning: could not associate commits with the Sentry release' >&2
fi
"$sentry_cli" releases finalize "$release"
