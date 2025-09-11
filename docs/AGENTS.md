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
