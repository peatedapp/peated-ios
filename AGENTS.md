# Repository Guidelines

## Scope & Precedence
- Root rules apply to the entire repository. Child AGENTS.md files add module-specific constraints and context; they do not relax root rules.
 
## Project Structure & Module Organization
- `Peated/` — iOS app target, Xcode project (`Peated.xcodeproj`), UI and app entry. Tests in `PeatedTests/` and `PeatedUITests/`.
- `PeatedCore/` — Swift Package with core models, utilities, and business logic (`Sources/`, `Tests/`).
- `PeatedAPI/` — Swift Package for API client and types; includes helper scripts for schema fixes and regeneration.
- `Scripts/` — repo-level helper scripts (e.g., API update).
- `docs/` — documentation and project notes.

## Documentation
- Docs guide: @docs/AGENTS.md
- API spec: @docs/specs/openapi-workflow.md
- Integration/setup: @docs/how-to/api-integration.md, @docs/how-to/google-signin-setup.md, @docs/how-to/fix-url-scheme.md, @docs/how-to/testing-strategy.md
- Design: @docs/design/architecture, @docs/design/components, @docs/design/data, @docs/design/offline, @docs/design/screens
- Reference: @docs/reference/svg-conversion-options.md

## Build, Test, and Development Commands
- Open Xcode: `open Peated/Peated.xcodeproj`
- Build/Test app: `xcodebuild -project Peated/Peated.xcodeproj -scheme Peated build|test`
- Build/Test packages: from package dir, `swift build` / `swift test`
- Regenerate API types: `./Scripts/update-api.sh` (or `PeatedAPI/update-api.sh`)

## Coding Style & Naming Conventions
- Swift; 4 spaces; prefer `private`/`fileprivate`.
- Types `UpperCamelCase`; funcs/vars `lowerCamelCase`; one top-level type per file (e.g., `BottleDetailView.swift`).
- UI lives in `Peated/`. Packages must not depend on the app target or import app UI.

- XCTest or Swift Testing. Package tests in `PeatedCore/Tests`, `PeatedAPI/Tests`; app/UI in `PeatedTests/`, `PeatedUITests/`.
- Name files `TypeNameTests.swift`; methods `test…()`.
- Add tests with new logic/fixes; avoid real network calls.

## Commit & Pull Request Guidelines
- Commits: imperative subject (≤72 chars); include rationale when non-trivial.
- PRs: clear description, linked issues, before/after screenshots for UI; include tests for affected code.

## Security & Configuration Tips
- Never commit secrets/tokens. After `update-api.sh`, run tests and review diffs for breaking changes.
