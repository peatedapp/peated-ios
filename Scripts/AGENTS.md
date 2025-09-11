# Repository Guidelines (Scripts)

## Scope & Contents
- Applies only to `Scripts/`; root AGENTS.md also applies.
- Contains repo-level helper scripts. Primary entry point: `update-api.sh` (convenience wrapper for PeatedAPI regeneration).

## Hard Rules
- Do not modify generated API code directly; always regenerate via scripts.
- After running an API update, run `swift build && swift test` and update dependents in the same PR.
- Scripts must be macOS-compatible (`bash`, POSIX utilities). Avoid interactive prompts.

## Entry Points
- From repo root (preferred): `./Scripts/update-api.sh`
- From API package: `cd PeatedAPI && ./update-api.sh`

## What `update-api.sh` Does
- Changes directory into `PeatedAPI/` and invokes that package’s `update-api.sh`.
- Downloads the OpenAPI spec, normalizes it, and regenerates `Sources/PeatedAPI/Generated/` using Swift OpenAPI Generator.

## Requirements
- Network access, `curl`, `sed`, Xcode/Swift toolchain.
- `swift-openapi-generator` (optional): used if installed; otherwise runs via `swift run`.

## Examples
- Update from root and verify:
  - `./Scripts/update-api.sh && (cd PeatedAPI && swift build && swift test)`

## Maintenance
- Keep scripts idempotent, with clear echo logs and non-zero exit on failure.
- If adding scripts, prefer small, composable Bash with comments and explicit paths.
