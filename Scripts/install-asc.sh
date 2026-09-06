#!/bin/bash

set -euo pipefail

ASC_VERSION='5.0.0'
INSTALL_DIRECTORY="${1:-/usr/local/bin}"
PLATFORM=''
ARCHITECTURE=''
EXPECTED_SHA256=''

case "$(uname -s)" in
    Darwin)
        PLATFORM='macOS'
        ;;
    Linux)
        PLATFORM='linux'
        ;;
    *)
        echo "error: unsupported operating system: $(uname -s)" >&2
        exit 1
        ;;
esac

case "$(uname -m)" in
    arm64 | aarch64)
        ARCHITECTURE='arm64'
        ;;
    x86_64 | amd64)
        ARCHITECTURE='amd64'
        ;;
    *)
        echo "error: unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

case "${PLATFORM}_${ARCHITECTURE}" in
    linux_amd64)
        EXPECTED_SHA256='76dc06fab91b0f6db73f42bb977fa1f61817b5ee5cb0958a38408f1aceeb3415'
        ;;
    linux_arm64)
        EXPECTED_SHA256='f457c466e869bcf1824795f493d4b9169644d7784f0dd124dedd08461c3d5099'
        ;;
    macOS_amd64)
        EXPECTED_SHA256='b5ce1901558f26b56fe2dd08138e760d647f2772a8e75047197e0ef5b2199263'
        ;;
    macOS_arm64)
        EXPECTED_SHA256='7e1d5dfafa053555f4db63478dbcba6f2a39b1563b2171ca3f4b6404f27afbb0'
        ;;
esac

TEMPORARY_DIRECTORY="$(mktemp -d)"
trap 'rm -rf "$TEMPORARY_DIRECTORY"' EXIT

ASSET="asc_${ASC_VERSION}_${PLATFORM}_${ARCHITECTURE}"
DOWNLOAD_PATH="$TEMPORARY_DIRECTORY/$ASSET"
DOWNLOAD_URL="https://github.com/rorkai/App-Store-Connect-CLI/releases/download/${ASC_VERSION}/${ASSET}"

curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
    --output "$DOWNLOAD_PATH" "$DOWNLOAD_URL"

if command -v sha256sum >/dev/null 2>&1; then
    printf '%s  %s\n' "$EXPECTED_SHA256" "$DOWNLOAD_PATH" | sha256sum --check --status
else
    ACTUAL_SHA256="$(shasum -a 256 "$DOWNLOAD_PATH" | awk '{ print $1 }')"
    if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
        echo 'error: asc download checksum mismatch' >&2
        exit 1
    fi
fi

mkdir -p "$INSTALL_DIRECTORY"
install -m 0755 "$DOWNLOAD_PATH" "$INSTALL_DIRECTORY/asc"
"$INSTALL_DIRECTORY/asc" version
