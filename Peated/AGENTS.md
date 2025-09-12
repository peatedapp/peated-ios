# Peated iOS App — Hard Rules

## Scope
- Applies to `Peated/` (the iOS app target). Some agents do not cascade AGENTS.md; this file restates critical rules.

## Hard Rules
- UI lives here; packages must not import app UI or depend on the app target.
- App may depend on `PeatedCore/` and `PeatedAPI/`; never the other way around.
- Tests for the app live in `PeatedTests/` and `PeatedUITests/` only.
- Never commit secrets/tokens.

## Build & Run
- Project/scheme: `Peated/Peated.xcodeproj` / `Peated`.
- Standard simulator device: `iPhone 16 Pro` (latest iOS).
- Prefer single‑call MCP flows to save context:
  - Build + Run: `xcodebuildmcp__build_run_sim({ projectPath: "Peated/Peated.xcodeproj", scheme: "Peated", simulatorName: "iPhone 16 Pro", useLatestOS: true })`
  - Build only: `xcodebuildmcp__build_sim({ projectPath: "Peated/Peated.xcodeproj", scheme: "Peated", simulatorName: "iPhone 16 Pro", useLatestOS: true })`
- Use multi‑step (build → install → launch) only when extra control is needed (custom args, log capture, explicit reinstall).

## Testing
- UI tests: use a single simulator — `iPhone 16 Pro`.
- Add tests with new logic/fixes; avoid real network calls.

## References
- Testing strategy: @docs/how-to/testing-strategy.md
- Google Sign‑In setup: @docs/how-to/google-signin-setup.md
- URL scheme fixes: @docs/how-to/fix-url-scheme.md
