# Repository Guidelines

## Scope and precedence

- These rules apply to the entire repository.
- Read the nearest child `AGENTS.md` before working in a module. Child instructions add module-specific requirements but do not relax these rules.
- Keep changes focused. Preserve unrelated work in a dirty worktree.

## Repository layout

- `Peated/` — iOS application, Xcode project, app tests, and UI tests.
- `PeatedCore/` — Swift package containing models, persistence, services, and business logic.
- `PeatedAPI/` — Swift package containing the generated OpenAPI client and API types.
- `Scripts/` — repository and API-generation utilities.
- `docs/` — architecture, design, workflow, and setup documentation.

`Peated` may depend on `PeatedCore` and `PeatedAPI`, and `PeatedCore` may depend on `PeatedAPI`. Dependencies must never point back toward the app target, and app UI must remain in `Peated/`.

## Working practices

- Inspect `git status` before editing and review the final diff before handing work back.
- Use `rg` and `rg --files` for repository searches.
- Prefer small, direct changes over speculative abstractions or unrelated cleanup.
- Do not hand-edit files under `PeatedAPI/Sources/PeatedAPI/Generated/`. Regenerate them with `./Scripts/update-api.sh`.
- Never commit secrets, tokens, signing credentials, or local machine configuration.

## Build and verification

Run the strongest verification supported by the current host and relevant to the change. If a required Apple tool is unavailable, report that portion as unverified; missing tooling is not a test failure.

### Portable checks

- Shell syntax: `bash -n Scripts/*.sh PeatedAPI/*.sh Peated/ci_scripts/*.sh Peated/*.sh`
- JSON syntax: validate changed JSON with `jq empty <file>`.
- Patch hygiene: `git diff --check`.

### Swift packages

- `PeatedAPI`: run `swift build` and `swift test` from `PeatedAPI/`.
- `PeatedCore`: run `swift build` and `swift test` from `PeatedCore/`.
- Package compatibility may depend on Apple frameworks. Run what the host supports and identify anything that still requires macOS.

### iOS app

- Project: `Peated/Peated.xcodeproj`
- Scheme: `Peated`
- Standard simulator: `iPhone 16 Pro` using the latest installed iOS runtime.
- Prefer `xcodebuildmcp__build_run_sim` when the Xcode MCP tools are available.
- Command-line fallback on macOS:
  `xcodebuild -project Peated/Peated.xcodeproj -scheme Peated -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
- Run targeted app or UI tests when behavior changes. Use the same simulator name to avoid creating duplicate devices.

## Swift conventions

- Use four-space indentation.
- Types use `UpperCamelCase`; functions and properties use `lowerCamelCase`.
- Prefer `private` or `fileprivate` for implementation details.
- Keep one primary top-level type per file and name the file after that type.
- Favor protocols and dependency injection for package code that interacts with storage, networking, authentication, or time.
- Add tests for new logic and bug fixes. Tests must not depend on live network services.

## Documentation

- Documentation rules: @docs/AGENTS.md
- Testing strategy: @docs/how-to/testing-strategy.md
- API workflow: @docs/specs/openapi-workflow.md
- API integration: @docs/how-to/api-integration.md
- Architecture: @docs/design/architecture/overview.md
- Google Sign-In setup: @docs/how-to/google-signin-setup.md

Update relevant documentation when commands, architecture, setup, or user-visible behavior changes.

## Commits and pull requests

- Use imperative commit subjects no longer than 72 characters.
- Explain the rationale for non-trivial changes.
- Pull requests should summarize scope, verification, and known limitations. Include before/after screenshots for UI changes.
