# Documentation Guidelines (docs/)

## Scope & Purpose
- This AGENTS.md applies to the `docs/` tree. It defines how we structure, author, and reference documentation. Root AGENTS.md still governs repo‑wide rules.

## Organization
- specs: canonical specifications (e.g., @docs/specs/openapi-workflow.md). One spec per topic; fold examples/rationale into the spec.
- design: architecture, data, components, screens, offline patterns (e.g., @docs/design/architecture/overview.md).
- how-to: task guides (e.g., @docs/how-to/api-integration.md, @docs/how-to/google-signin-setup.md, @docs/how-to/testing-strategy.md).
- reference: language/platform references and one‑offs (e.g., @docs/reference/svg-conversion-options.md).
- notes: planning or status docs (e.g., @docs/notes/implementation/phases.md, @docs/notes/roadmap.md). Mark clearly if archived.

## Authoring Rules
- Keep docs focused and scoped. If it’s the source of truth, make it a spec; if it’s a procedure, make it a how‑to.
- Use kebab-case filenames and clear H1 titles. Prefer short sections with actionable steps.
- Start with a one‑sentence purpose. Add “Status: draft/active/archived” at top if helpful.
- Link using @-notation for cross‑repo references (e.g., @docs/specs/openapi-workflow.md). Use relative links within the same folder.
- Include minimal runnable examples where applicable (commands, code snippets).

## Maintenance
- Update or remove outdated docs. Do not create “example” or “improvements” files for specs; integrate that content into the spec itself.
- When moving files, update inbound links and AGENTS.md references in the same PR.
- Prefer additive edits; if restructuring, include a brief migration note at the top of changed docs.

## Quick Examples
- Create a new how‑to:
  - Path: `docs/how-to/add-feature-toggle.md`
  - Title: `# Add a Feature Toggle`
  - Content: prerequisites → steps → verify → rollback
- Reference the API update flow from code or AGENTS:
  - Use: @docs/specs/openapi-workflow.md

## Review
- Docs should be reviewed like code: clear purpose, accurate commands, and up‑to‑date paths. Include screenshots only when they clarify a non‑obvious step.

## Verifying Changes with xcodebuildmcp
- Goal: Use MCP tools to build, install, launch, and interact with the app to validate a change end‑to‑end.

- Prefer fewer tool calls (saves context)
  - When you just need to build and launch in the simulator, prefer a single call:
    - `xcodebuildmcp__build_run_sim({ projectPath: "Peated/Peated.xcodeproj", scheme: "Peated", simulatorName: "iPhone 16 Pro", useLatestOS: true })`
  - If you need only the build artifact (no launch yet), use:
    - `xcodebuildmcp__build_sim({ projectPath: "Peated/Peated.xcodeproj", scheme: "Peated", simulatorName: "iPhone 16 Pro", useLatestOS: true })`
  - Use the multi‑step flow (build → get path → install → launch) only when you specifically need that control (e.g., inspecting bundle ID, reinstalling between runs, or launching with custom args/log capture).

- Overview of tools (you don’t need every one on each run)
  - `xcodebuildmcp__list_schemes`, `xcodebuildmcp__list_sims`: discover what you can target.
  - `xcodebuildmcp__build_sim`: compile for a specific simulator.
  - `xcodebuildmcp__get_sim_app_path` → `xcodebuildmcp__get_app_bundle_id`: locate the built app and its bundle id.
  - `xcodebuildmcp__install_app_sim` → `xcodebuildmcp__launch_app_sim`: install and launch on the simulator.
  - `xcodebuildmcp__describe_ui`: fetch an accessibility tree with coordinates for precise taps (don’t guess).
  - `xcodebuildmcp__tap` / `xcodebuildmcp__gesture` / `xcodebuildmcp__screenshot`: interact and capture evidence.
  - `xcodebuildmcp__launch_app_logs_sim`: observe app logs during verification.

// Consistency tip: Prefer a single simulator name to avoid duplicates.
// Use the default "iPhone 16 Pro" simulator when possible.

- Typical verification workflow
  0) Quick path (build + run in one call)
     - `xcodebuildmcp__build_run_sim({ projectPath: "Peated/Peated.xcodeproj", scheme: "Peated", simulatorName: "iPhone 16 Pro", useLatestOS: true })`
  1) Prefer simulator name
     - Use: `simulatorName: 'iPhone 16 Pro'` (latest iOS)
     - Or: `xcodebuildmcp__list_sims({})` → copy a UUID if you must pin.
  2) Build for that simulator
     - By name: `xcodebuildmcp__build_sim({ projectPath: "Peated/Peated.xcodeproj", scheme: "Peated", simulatorName: "iPhone 16 Pro", useLatestOS: true })`
     - By UUID: `xcodebuildmcp__build_sim({ projectPath: "Peated/Peated.xcodeproj", scheme: "Peated", simulatorId: "<SIM_UUID>" })`
  3) Resolve app path and bundle id
     - `xcodebuildmcp__get_sim_app_path({ projectPath: "Peated/Peated.xcodeproj", scheme: "Peated", platform: "iOS Simulator", simulatorId: "<SIM_UUID>" })`
     - `xcodebuildmcp__get_app_bundle_id({ appPath: "<APP_PATH>" })`
  4) Install + launch
     - `xcodebuildmcp__install_app_sim({ simulatorUuid: "<SIM_UUID>", appPath: "<APP_PATH>" })`
     - By name: `xcodebuildmcp__launch_app_sim({ simulatorName: "iPhone 16 Pro", bundleId: "<BUNDLE_ID>" })`
     - By UUID: `xcodebuildmcp__launch_app_sim({ simulatorUuid: "<SIM_UUID>", bundleId: "<BUNDLE_ID>" })`
  5) Drive the UI with coordinates from the tree
     - `xcodebuildmcp__describe_ui({ simulatorUuid: "<SIM_UUID>" })`
     - Find an element’s frame; tap its center: `x = frame.x + frame.width/2`, `y = frame.y + frame.height/2`.
     - `xcodebuildmcp__tap({ simulatorUuid: "<SIM_UUID>", x: <X>, y: <Y> })`
     - Re‑run `describe_ui` after layout changes (new sheets, alerts, navigation).
  6) Capture signals
     - Logs: `xcodebuildmcp__launch_app_logs_sim({ simulatorUuid: "<SIM_UUID>", bundleId: "<BUNDLE_ID>" })`
     - Screenshots: `xcodebuildmcp__screenshot({ simulatorUuid: "<SIM_UUID>" })`

- Example: verify a Google Sign‑In cancel change
  - Build, install, launch (steps 1–4 above).
  - `describe_ui` → locate the “Continue with Google” button → `tap` it.
  - When the system sheet appears, `describe_ui` again → tap the “Cancel” button.
  - Expectation: no error alert appears; the login screen returns to idle.
  - If you need to prove absence of alert: immediately `describe_ui` and confirm there is no element with label like “Sign In Failed”.

- Tips & pitfalls
  - Always use `describe_ui` before taps; do not guess coordinates from screenshots.
  - Rebuild after code changes. To be safe, re‑install the app each time; DerivedData paths can change between builds.
  - If `launch` succeeds but UI doesn’t change, make sure you’re interacting with the foreground app and the correct simulator UUID.
  - Use log capture when debugging flows that fail silently.

Notes
- Project path: `Peated/Peated.xcodeproj`. Scheme: `Peated`.
- Bundle ID: `com.peated.Peated` (also discoverable via `get_app_bundle_id`).
