#!/bin/bash
# Turns off the Apple Intelligence banner on the named iPhone simulator and
# prints its UDID for xcodebuild.
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
    xcrun simctl boot "$udid"
fi

# On Apple Intelligence-capable hosts, iOS 26 posts a "Ready for Apple
# Intelligence" banner about four minutes after boot. The banner lands mid-run
# and stalls XCUIApplication.terminate() until it times out. Recording that the
# banner was already sent stops generativeexperiencesd from posting it. The
# value is a simulator user default, so it survives a shutdown.
xcrun simctl spawn "$udid" defaults write com.apple.generativeexperiences.corefollowup \
    DateOfLastAppleIntelligenceReadinessCFU -date "$(date -u '+%Y-%m-%d %H:%M:%S +0000')"

# xcodebuild attaches the simulator's system log to the result bundle only when
# it boots the device itself, so hand back a device in the state it was found.
if [ "$state" != "Booted" ]; then
    xcrun simctl shutdown "$udid"
fi

printf '%s\n' "$udid"
