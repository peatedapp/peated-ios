# Migrate the App to Swift 6

This guide defines the staged migration from Swift 5 language mode to Swift 6 data-race safety.

Status: active

## Current state

- `PeatedAPI` and `PeatedCore` use Swift tools 6.0.
- The Xcode app and test targets remain in Swift 5 language mode.
- Complete strict-concurrency checking is enabled at the Xcode project level.
- CI compiles with Xcode 26.6 and reports concurrency diagnostics.

Keeping the language-mode switch separate lets the repository review isolation and ownership changes before the compiler turns remaining diagnostics into errors.

## Migration rules

- Fix the owning isolation or data-flow problem. Do not silence a diagnostic with `@unchecked Sendable`, `nonisolated(unsafe)`, or an unstructured dispatch hop unless the unsafe contract is real, documented, and reviewed.
- Keep SwiftUI state and UI-facing observable models on `MainActor`.
- Keep database, network, image processing, and other potentially blocking work off the main actor.
- Prefer immutable `Sendable` values across isolation boundaries.
- Replace callback and lock bridges with actors or checked continuations only when they clarify ownership.
- Preserve cancellation. A task created for a screen or selection must not apply stale results after that owner changes.
- Review every existing `@unchecked Sendable` and `Task.detached` use explicitly.

## Sequence

1. Build all app and test targets with complete strict-concurrency checking.
2. Group diagnostics by owning type or boundary. Fix one ownership problem at a time.
3. Run the relevant package tests and app tests after each group.
4. Run UI tests for changes to main-actor state, cancellation, navigation, or lifecycle work.
5. Change the app and test targets to Swift 6 language mode only after the diagnostic set is empty.
6. Treat new compiler warnings as errors after the Swift 6 switch is stable.

## Verification

```bash
make test-packages
make test-ios
make verify
```

Inspect the build log for strict-concurrency diagnostics even when the Swift 5 build succeeds. The migration is complete only when the app and both test targets compile in Swift 6 language mode without unsafe compatibility annotations added only to suppress errors.

## Reference

- [Adopting strict concurrency in Swift 6 apps](https://developer.apple.com/documentation/swift/adoptingswift6)
