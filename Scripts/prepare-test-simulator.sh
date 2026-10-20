#!/bin/bash
# Boots the named iPhone simulator for UI tests and prints its UDID.
#
# Usage: Scripts/prepare-test-simulator.sh 'iPhone 17 Pro'
#
# Picks the device with that name on the newest installed iOS runtime, which
# is the device xcodebuild picks for `name=` without an OS.
set -euo pipefail

name="${1:?usage: prepare-test-simulator.sh <device name>}"

device="$(xcrun simctl list devices available -j | jq -r --arg name "$name" '
    .devices
    | to_entries
    | map(select(.key | startswith("com.apple.CoreSimulator.SimRuntime.iOS-")))
    | map(.key as $runtime | .value[] | select(.name == $name)
        | {udid, state, version: ($runtime | sub(".*iOS-"; "") | split("-") | map(tonumber))})
    | sort_by(.version)
    | last
    | select(. != null)
    | "\(.udid) \(.state)"')"

if [ -z "$device" ]; then
    echo "error: no available iOS simulator named '$name'" >&2
    exit 1
fi

udid="${device%% *}"
state="${device#* }"

if [ "$state" != "Booted" ]; then
    echo "Booting $name ($udid)" >&2
    xcrun simctl boot "$udid"
fi

# On Apple Intelligence-capable hosts, iOS 26 posts a "Ready for Apple
# Intelligence" banner about four minutes after first boot. The banner lands
# mid-run and stalls XCUIApplication.terminate() until it times out. Recording
# that the banner was already sent stops generativeexperiencesd from posting it.
# This must run before that first check, so it runs right after boot.
xcrun simctl spawn "$udid" defaults write com.apple.generativeexperiences.corefollowup \
    DateOfLastAppleIntelligenceReadinessCFU -date "$(date -u '+%Y-%m-%d %H:%M:%S +0000')"

printf '%s\n' "$udid"
