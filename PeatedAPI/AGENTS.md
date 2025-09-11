# Repository Guidelines (PeatedAPI package)

## Scope & Contents
- Applies only to `PeatedAPI/`; root AGENTS.md also applies.
- Purpose: API client(s), transport, and generated types.
- Layout: `Sources/` (code), `Tests/` (XCTest). Scripts: `update-api.sh`, `fix-nullable-fields.sh`, `fix-parameter-schemas.sh`.

## Build & Test
- Build: `swift build`
- Test: `swift test`

## API Generation
- Update from spec: `./update-api.sh`
- After generation, run: `swift build && swift test`
- Internal-only: compatibility may be broken freely. Review diffs and adapt app usage/tests in the same PR.

### How to run
- From repo root: `./Scripts/update-api.sh`
- From package dir: `./update-api.sh`
- Output: updates `Sources/PeatedAPI/openapi.json` and regenerates `Sources/PeatedAPI/Generated/`.
- Requirements: network access, `curl`, `sed`, Swift toolchain. The script uses `swift-openapi-generator` if installed; otherwise it runs it via `swift run`.
- After running: `git diff` to review, then `swift build && swift test` before committing.

## Hard Rules
- No UI and no persistence; networking only.
- Do not manually edit generated files; use scripts.
- Provide a single transport abstraction; feature clients compose it.
- Must not depend on `Peated` or `PeatedCore` (no cross-package dependency).

## Meta
- Role: source of truth for HTTP contracts and API models.
- Testing: mock transport; avoid real network calls.

## Docs
- Docs guide: @docs/AGENTS.md
- OpenAPI workflow: @docs/specs/openapi-workflow.md
