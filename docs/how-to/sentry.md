# Sentry

This guide explains what the iOS app reports to Sentry, how to add a report, and how release builds get readable stack traces.

Status: active

## How it fits together

- `PeatedCore` depends only on the `TelemetryReporter` protocol and the `Telemetry` entry point in `PeatedCore/Sources/PeatedCore/Telemetry/`.
- `ErrorReport` turns an error into a safe projection: a feature, an operation, a stable kind such as `decoding.key_not_found`, a short summary, and the generated API operation id. It returns `nil` for expected failures.
- `Peated/Peated/Services/SentryTelemetryReporter.swift` starts the SDK and sends those projections to Sentry. It is the only file that imports `Sentry`.
- The Sentry project is `peated/ios`.

## What is reported

- Unexpected failures captured with `Telemetry.capture(error, feature:operation:)` at the boundary that owns them: the model, repository, or service that decides what the user sees.
- Crashes and app hangs, through the SDK.
- Breadcrumbs for every API call (operation id, method, status, duration), network changes, and offline sync attempts.
- Spans for API calls as `http.client` children of the SDK's app start and screen transactions.
- Structured logs for the allowlisted fields in `PeatedCore.Logger`.
- The signed-in account id, set from `AuthenticationManager.authState` and cleared on sign-out.

## What is never reported

- Cancellation, offline network errors, timeouts, rejected input (4xx), expired sessions, terms acceptance, and Google sign-in cancellation. `ErrorReport` drops the first group; `AuthenticationManager` and `LocationService` filter their own provider errors before capturing.
- URLs, query strings, request or response bodies, OpenAPI client descriptions, server error messages, usernames, email addresses, IP addresses, screenshots, view hierarchies, and session replay.
- Bounded retries. `OfflineQueueManager` records a breadcrumb per attempt and captures only the terminal failure.

## Environments

`BuildDistribution` selects the environment at launch:

| Build | Environment |
| --- | --- |
| Debug | `development` |
| TestFlight (sandbox receipt) | `testflight` |
| App Store | `production` |

The release is the SDK default, `com.peated.Peated@<version>+<build>`.

## Add a capture

Capture once, in the `catch` that owns recovery:

```swift
} catch {
    Telemetry.capture(error, feature: "bottle", operation: "toggle_library")
    // revert optimistic state, show the user an error
}
```

- `feature` is the owning noun (`feed`, `tasting`, `bottle`, `auth`). `operation` is the action (`load`, `submit`, `toggle_toast`). Keep both stable and low-cardinality; they become the issue fingerprint.
- Do not capture and rethrow the same error at several layers. Lower layers throw; the owner captures.
- Pass only scalar `attributes` such as counts and sizes. Never pass text the user typed, image data, or identifiers of other people.
- Expected outcomes that `ErrorReport` cannot recognise (for example a provider's "no results" error) are filtered at the call site before capturing.

Telemetry never throws and never changes product behavior. Tests assert user-visible outcomes, not `Telemetry` calls; only the telemetry tests in `PeatedCore/Tests/PeatedCoreTests/Telemetry/` assert reporter behavior.

## Debug symbols

Xcode Cloud runs `Peated/ci_scripts/ci_post_xcodebuild.sh` after each archive. It installs a pinned `sentry-cli`, uploads the archive's dSYMs with source context, and creates and finalizes the release.

The script needs `SENTRY_AUTH_TOKEN` in the Xcode Cloud workflow environment:

1. In Sentry, open **Settings → Developer Settings → Organization Auth Tokens** and create a token for the `peated` organization. The default scopes (`org:read`, `project:releases`) are enough.
2. In App Store Connect, open the `Release to TestFlight` workflow, choose **Environment**, and add `SENTRY_AUTH_TOKEN` as a secret variable.

Without the token the script prints a warning and the archive continues, but crashes from that build will not be symbolicated.

Local archives use the `Upload Debug Symbols to Sentry` build phase in the Xcode project, which runs only when `sentry-cli` is installed.

## Verify

- Run a debug build, force a failure such as turning the API base URL to an invalid host in Developer Settings, and confirm an issue appears in `peated/ios` under the `development` environment with `feature`, `operation`, and `error.kind` tags.
- After a TestFlight build, open **Settings → Projects → ios → Debug Files** in Sentry and confirm the new build's dSYMs are listed.
- Confirm the release `com.peated.Peated@<version>+<build>` appears under **Releases** once the build has been launched.
