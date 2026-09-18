# App Store Connect and Xcode Cloud

This guide defines the supported release path and keeps routine validation from consuming the monthly Xcode Cloud allowance.

Status: active

## Responsibilities

- GitHub Actions runs portable checks and Apple build/tests for each pull request and push to `main`.
- Xcode Cloud performs release archives and internal TestFlight distribution only when a person starts it.
- App Store Connect manages processed builds, TestFlight groups, release metadata, and App Review.
- The `asc` CLI is the supported command-line interface for App Store Connect and Xcode Cloud operations.

Do not configure Xcode Cloud to build every commit or pull-request update. This repository is public, so its standard GitHub-hosted macOS checks do not consume paid GitHub Actions minutes or Apple Xcode Cloud compute hours.

## Install the CLI

On macOS:

```bash
make bootstrap
asc version
```

Automation installs the reviewed `asc` 5.0.0 binary with `@Scripts/install-asc.sh` and verifies its SHA-256 digest before execution.

## Authenticate locally

Prefer an individual App Store Connect API key for a user whose app access is limited to Peated. A team key applies to every app in the organization.

Store the key in the macOS Keychain:

```bash
asc telemetry disable
asc auth login \
    --name Peated \
    --key-type individual \
    --key-id '<key-id>' \
    --private-key '/path/to/AuthKey.p8' \
    --network
```

For a team key, omit `--key-type individual` and add `--issuer-id '<issuer-id>'`. Never put the key, token, or an `.asc/config.json` file in the repository.

Verify access:

```bash
asc auth status --validate
make xcode-cloud-list
```

## Live Xcode Cloud workflow

Keep one active workflow named `Release to TestFlight` with these settings:

- Start condition: manual only
- Xcode: 26.6
- Clean build: off by default
- Action: archive the Peated iOS app
- Post-action: distribute to the internal Peated TestFlight group
- Automatic pull-request and branch-change triggers: disabled

The workflow should not add separate Build, Test, or Analyze actions. The tagged or selected commit must already have passed the required GitHub `Apple build and tests` check. Run broader analysis or device matrices locally or in a deliberately started diagnostic workflow.

Most Xcode Cloud workflow settings are available through the App Store Connect API. TestFlight post-actions are not in Apple's public workflow schema and must be configured in App Store Connect or with an authenticated `asc web xcode-cloud` session. Use `asc xcode-cloud workflows view` after any change to verify the public live configuration.

## Run a release archive

From a trusted local shell:

```bash
make xcode-cloud-run \
    ASC_XCODE_CLOUD_WORKFLOW='Release to TestFlight' \
    XCODE_CLOUD_BRANCH=main
```

The command waits up to two hours by default. Override `XCODE_CLOUD_TIMEOUT` only when a legitimate release archive needs longer.

Alternatively, open GitHub Actions, choose `Xcode Cloud`, select **Run workflow**, and enter the reviewed branch or tag. The dispatcher waits for Xcode Cloud and fails when the Apple build fails.

Use a clean build only to diagnose a suspected cache problem. Routine release archives should preserve Xcode Cloud dependency caching.

## GitHub dispatcher configuration

Configure these repository variables:

- `ASC_APP_ID`: `com.peated.Peated`
- `ASC_KEY_TYPE`: `individual` or `team`
- `ASC_XCODE_CLOUD_WORKFLOW`: `Release to TestFlight`

Configure these Actions secrets:

- `ASC_KEY_ID`
- `ASC_PRIVATE_KEY_B64`: base64-encoded contents of the `.p8` key
- `ASC_ISSUER_ID`: required only for a team key

Use a dedicated key. Do not reuse a personal release key with broader permissions than the dispatcher needs. Rotate the key immediately if it is exposed.

## Compute policy

- Keep Xcode Cloud automatic start conditions disabled.
- Do not mirror the GitHub pull-request test matrix in Xcode Cloud.
- Use one simulator destination in routine GitHub validation.
- Archive only reviewed commits that passed required checks.
- Check usage in App Store Connect after releases and before enabling any scheduled workflow.
- Do not purchase more compute until release archives alone approach the included allowance.

## References

- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Xcode Cloud workflows and builds](https://developer.apple.com/documentation/appstoreconnectapi/xcode-cloud-workflows-and-builds)
- [Xcode Cloud pricing and compute hours](https://developer.apple.com/xcode-cloud/get-started/)
