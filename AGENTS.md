# Agent Instructions

## Core Principles

- Write for normal humans. Use short sentences, active voice, and consistent terms in documentation, plans, comments, and explanations.
- Optimize for the next maintainer. Choose the smallest design that closes the proven failure. Avoid speculative abstractions, configuration, recovery paths, and dependencies.
- Prefer functions, value types, small protocols, and focused modules. Expose narrow capabilities and use the same domain noun for the same concept.
- Keep identity, ownership, permissions, private data, persistence, cancellation, and irreversible actions explicit at their runtime boundaries.

## Toolchain

- The root `Makefile` is the canonical command interface. Run `make help` to list commands and `make doctor` to inspect the host.
- Install macOS command-line tools with `make bootstrap`.
- Core commands: `make check`, `make lint`, `make test-packages`, `make test-ios`, and `make verify`.
- On Linux, use `make lint-docker` and `make test-api-docker` where Apple frameworks are not required.
- Use the repository-selected Xcode and Swift versions. Do not silently upgrade generated projects, lockfiles, or package requirements with another toolchain.

## File-Scoped Commands

| Task | Command |
| --- | --- |
| Format one Swift file | `swiftformat path/to/File.swift --config .swiftformat` |
| Lint one Swift file | `swiftlint lint --config .swiftlint.yml --baseline .swiftlint-baseline.json path/to/File.swift` |
| Test PeatedAPI | `(cd PeatedAPI && swift test)` |
| Test PeatedCore | `(cd PeatedCore && swift test)` |
| Test one app test | `xcodebuild -project Peated/Peated.xcodeproj -scheme Peated -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:PeatedTests/<suite>/<test> test` |

## Workflow

- For non-trivial changes: discover, implement the smallest useful vertical slice, verify it, and summarize the result.
- Inspect `git status` before editing. Preserve unrelated work in a dirty worktree. Review the final diff before handoff.
- Use `rg` and `rg --files` for searches.
- Search every consumer before changing a shared signature, error contract, generated schema, persisted format, or domain name. Use a hard cutover unless compatibility is explicitly required.
- Let unexpected failures reach the owning boundary. Retry only expected transient failures.
- Keep non-obvious ownership and invariant comments beside the code that enforces them.
- Move durable explanations beside the package, module, or feature that owns them. Delete completed plans and stale copied reference material.
- After code changes, run the smallest relevant tests, compiler checks, lint, and format checks. Use simulator QA when automation does not prove the changed behavior. Report checks that you did not run.

## Testing and Validation

- Use Swift Testing for new unit and integration tests. Keep XCTest for UI tests and APIs that Swift Testing does not cover.
- Tests prove behavior and durable outcomes, not implementation steps, logs, spans, or Sentry calls.
- Search existing test layers before adding coverage. Test each contract at its highest useful owning boundary and do not duplicate it across several layers.
- Package and app tests must not depend on live network services. Use injected clients, repositories, clocks, and stores.
- UI changes require targeted simulator QA. Check accessibility when a screen, control, navigation path, or content hierarchy changes.
- The standard simulator is `iPhone 16 Pro` with the latest installed iOS runtime.
- Prefer `xcodebuildmcp__build_run_sim` when available. The command-line fallback is `make build-ios` or `make test-ios`.
- Run the strongest verification supported by the host. Missing Apple tooling is an unverified check, not a test failure.

## Architecture Conventions

- `Peated/` owns the iOS app, SwiftUI, app tests, and UI tests.
- `PeatedCore/` owns models, persistence, services, repositories, and business logic.
- `PeatedAPI/` owns the generated OpenAPI client and API types.
- `Peated` may depend on `PeatedCore` and `PeatedAPI`. `PeatedCore` may depend on `PeatedAPI`. Dependencies must never point back toward the app.
- Keep framework and vendor SDK details in their owning adapter. Shared code should depend on Peated-owned contracts.
- Favor protocols and dependency injection at storage, networking, authentication, location, and time boundaries. Do not create a protocol for an implementation that has no boundary or alternate behavior.
- Keep one primary top-level type per file and name the file after that type.
- Use four-space indentation. Types use `UpperCamelCase`; functions and properties use `lowerCamelCase`.
- Prefer `private` or `fileprivate` for implementation details.
- Do not hand-edit `PeatedAPI/Sources/PeatedAPI/Generated/`. Regenerate it with `./Scripts/update-api.sh`.
- Never commit secrets, tokens, signing credentials, or local machine configuration.

## Where Rules Live

Read the relevant policy and owning feature documentation before changing code in that area.

| Need | Source |
| --- | --- |
| Repo-wide policy index | `docs/policies/README.md` |
| Correctness and interfaces | `docs/policies/correctness-complexity.md`, `docs/policies/interface-design.md` |
| Errors, concurrency, and durable work | `docs/policies/error-handling.md`, `docs/policies/background-work.md` |
| API, storage, auth, and external inputs | `docs/policies/runtime-boundaries.md` |
| Comments, telemetry, and private data | `docs/policies/code-comments.md`, `docs/policies/observability.md`, `docs/policies/data-redaction.md` |
| SwiftUI and accessibility | `docs/policies/swiftui-accessibility.md` |
| Development toolchain | `docs/how-to/toolchain.md` |
| App Store Connect and Xcode Cloud | `docs/how-to/app-store-connect.md` |
| Swift 6 migration | `docs/how-to/swift-6-migration.md` |
| Testing strategy | `docs/how-to/testing-strategy.md` |
| API generation workflow | `docs/specs/openapi-workflow.md` |
| API integration | `docs/how-to/api-integration.md` |
| Backend, API, and redesign sync | `docs/how-to/sync-peated-upstream.md` |
| Upstream migration status | `docs/notes/upstream-migration.md` |
| Architecture | `docs/design/architecture/overview.md` |
| Google Sign-In setup | `docs/how-to/google-signin-setup.md` |
| Module-specific rules | Nearest child `AGENTS.md` |

Policy documents contain repo-wide defaults. Feature architecture and non-obvious invariants belong in the owning package, module, or feature documentation. Code, generated API contracts, exported types, and tests are authoritative. Temporary notes and plans cannot override policy.

## Commits and Pull Requests

- Use imperative commit subjects no longer than 72 characters.
- Explain the rationale for non-trivial changes.
- Pull requests summarize scope, verification, and known limitations.
- Include before-and-after screenshots for visible UI changes.
