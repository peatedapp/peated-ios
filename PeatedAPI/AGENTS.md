# PeatedAPI (Swift Package) — Hard Rules

## Scope
- Applies to `PeatedAPI/` (API client and types). Some agents do not cascade AGENTS.md; this file restates critical rules.

## Hard Rules
- Generated types: do not hand‑edit generated files; use the provided update scripts and schema fix helpers.
- Regenerate API types via:
  - `./Scripts/update-api.sh` (repo‑level) or
  - `PeatedAPI/update-api.sh` (package‑local)
- After regeneration: run tests and review diffs for breaking changes.
- Never commit secrets/tokens.

## Build & Test
- From `PeatedAPI/`: `swift build` / `swift test`.
- Tests live under `PeatedAPI/Tests` and should use mocks (no live network).

## References
- API workflow spec: @docs/specs/openapi-workflow.md
- API integration guide: @docs/how-to/api-integration.md
- Testing strategy: @docs/how-to/testing-strategy.md
