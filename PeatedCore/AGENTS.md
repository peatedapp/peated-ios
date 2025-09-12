# PeatedCore (Swift Package) — Hard Rules

## Scope
- Applies to `PeatedCore/` (models, utilities, business logic). Some agents do not cascade AGENTS.md; this file restates critical rules.

## Hard Rules
- Pure package: no UI frameworks (no SwiftUI/UIKit) and no imports from the app target.
- Favor protocols + dependency injection for testability.
- Add tests with any new logic or fixes.

## Build & Test
- From `PeatedCore/`: `swift build` / `swift test`.
- Tests live under `PeatedCore/Tests` and should not rely on real network calls.

## References
- Testing strategy: @docs/how-to/testing-strategy.md
- Architecture overview: @docs/design/architecture/overview.md
