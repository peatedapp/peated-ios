# Testing Peated iOS

This guide defines the maintained test layers and commands for Peated iOS.

Status: active

## Principles

- Test behavior and durable outcomes, not implementation steps.
- Test a contract at its highest useful owning boundary.
- Keep tests deterministic. Do not use live network services, production accounts, wall-clock delays, or shared external state.
- Inject clients, repositories, clocks, stores, and connectivity when code crosses those boundaries.
- Use the smallest test layer that proves the behavior.

## Frameworks

- Use Swift Testing for new unit and integration tests.
- Keep XCTest for XCUITest and APIs that Swift Testing does not cover.
- Use hand-written fakes or stubs that implement production protocols. Add a mocking framework only when it solves a demonstrated maintenance problem.
- Test presentation logic through its observable model. Use UI tests for real navigation, accessibility, system integration, and critical user journeys.

## Test layers

### Package tests

`PeatedAPI` tests generated-client decoding and API boundary behavior:

```bash
make test-api
```

`PeatedCore` tests repositories, persistence, models, authentication, caching, offline work, and data transformations:

```bash
make test-core
```

Run both packages on an Apple host with:

```bash
make test-packages
```

Linux can run the portable API package with the pinned Swift container:

```bash
make test-api-docker
```

### App tests

`Peated/PeatedTests/` owns app-target logic and integration tests that require the application module:

```bash
make test-ios
```

The command writes `.test-results/Peated.xcresult`. Open that bundle in Xcode to inspect failures, attachments, diagnostics, and coverage when enabled.

### UI tests

`Peated/PeatedUITests/` owns a small set of critical end-to-end journeys. UI tests should:

- launch into a deterministic state through launch arguments or injected test configuration
- query controls by role, label, or stable accessibility identifier
- wait for observable state instead of sleeping
- verify user-visible outcomes
- attach useful screenshots only on failure
- run an accessibility audit for each important screen or workflow

Do not use UI tests to prove repository or model behavior that a faster package or app test can own.

## Swift Testing conventions

- Group related tests in a suite type.
- Give tests behavior-focused names.
- Use parameterized tests for the same contract over several inputs.
- Use `#require` when later assertions need a value to exist.
- Preserve parallel execution. Mark a suite serialized only when shared mutable state is an unavoidable part of the contract.
- Use traits for real runtime conditions, time limits, and cross-cutting tags. Do not tag every test without a filtering need.

## Time and concurrency

- Inject a clock for debounce, cache expiry, retry, and timeout behavior.
- Prefer continuations, confirmations, or observable state over `Task.sleep`.
- Test cancellation and stale-result rejection for work that can outlive its initiating screen or selection.
- Test offline mutations for idempotency, process-resume state, bounded retry, and reconciliation after an ambiguous remote result.

## Simulator verification

The local standard is `iPhone 16 Pro` with the latest installed iOS runtime. GitHub Actions uses `iPhone 17 Pro` because that device is installed on the pinned macOS 26 image.

Prefer the XcodeBuildMCP build-and-run flow when available. Otherwise use:

```bash
make build-ios
make test-ios
```

For visible UI changes, manually verify the changed workflow and inspect loading, empty, offline, error, and success states. Also check the smallest supported iPhone, iPad layout, VoiceOver, and large Dynamic Type when the layout can be affected.

## Diagnostic runs

Use Xcode test-plan or scheme diagnostics for focused investigation:

- Address Sanitizer for memory access defects
- Thread Sanitizer for runtime races across Swift, Objective-C, and C boundaries
- Main Thread Checker for UI access
- repeated or randomized test execution for order dependence and flakes

These runs are slower. Use them for relevant changes and scheduled diagnostics rather than every edit.

## Coverage

Coverage identifies untested risk; it is not a quality score. Review coverage for changed domain, persistence, and boundary code. Do not add low-value assertions only to increase a percentage.

Use `xccov view --report .test-results/Peated.xcresult` when the result bundle includes coverage.

## References

- [Swift Testing](https://developer.apple.com/documentation/testing)
- [Xcode test plans](https://developer.apple.com/documentation/xcode/organizing-tests-to-improve-feedback)
- [Accessibility audits](https://developer.apple.com/documentation/accessibility/performing-accessibility-audits-for-your-app)
