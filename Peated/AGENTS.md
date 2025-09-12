# Repository Guidelines (Peated app)

## Scope & Contents
- Applies only to the `Peated/` app module; root AGENTS.md also applies.
- Xcode project: `Peated.xcodeproj`
- Source: `Peated/Peated/`
- Config: `Configuration/`; CI helpers: `ci_scripts/`
- Tests: `PeatedTests/` (unit), `PeatedUITests/` (UI)

## Build & Test
- Open project: `open Peated.xcodeproj`
- Build: `xcodebuild -project Peated.xcodeproj -scheme Peated build`
- Test (standard simulator):
  - `xcodebuild -project Peated.xcodeproj -scheme Peated -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test`
  - Use this destination consistently to avoid duplicate simulators.

## Hard Rules
- UI-only module: no business logic, persistence, or networking here.
- All network access goes through `PeatedAPI`; all shared logic/models live in `PeatedCore`.
- The app must not be imported by any package; keep boundaries one-directional (app -> packages).

## Meta
- Role: composition root, navigation, and presentation. Non-UI code belongs in packages.
- Snapshot/UI tests live in `PeatedUITests/`.

## Docs
- Docs guide: @docs/AGENTS.md
- Architecture/UI patterns: @docs/design/architecture, @docs/design/components, @docs/design/screens
- Platform setup: @docs/how-to/google-signin-setup.md, @docs/how-to/fix-url-scheme.md

## PRs
- Keep PRs focused; include screenshots for UI changes. Link issues; describe behavior changes and testing.
