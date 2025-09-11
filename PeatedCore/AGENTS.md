# Repository Guidelines (PeatedCore package)

## Scope & Contents
- Applies only to `PeatedCore/`; root AGENTS.md also applies.
- Purpose: core models, domain logic, and utilities shared across the app.
- Layout: `Sources/` (code), `Tests/` (XCTest)

## Build & Test
- Build: `swift build`
- Test: `swift test`

## Hard Rules
- No UIKit/SwiftUI and no platform UI frameworks.
- No networking, persistence, or OS-specific side effects; keep code deterministic.
- Must not depend on `Peated` (app) or `PeatedAPI` (no cross-package dependency).

## Meta
- Role: business/domain layer; reusable and testable in isolation.
- Tests should avoid time/network flakiness; prefer pure units.

## Change Management
- Internal-only: compatibility can be broken at any time.
- When breaking, update all dependents (app/tests) in the same PR.
- Keep changes purposeful; include a brief migration note in the PR.

## Docs
- Docs guide: @docs/AGENTS.md
- Design and data flows: @docs/design/architecture, @docs/design/data, @docs/design/offline
