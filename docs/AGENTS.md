# Documentation Guidelines

## Scope and Purpose

- These rules apply to `docs/`. The root `AGENTS.md` also applies.
- Documentation records durable policy, architecture, contracts, and procedures. It is not a substitute for code, generated schemas, exported types, or tests.

## Organization

- `policies/` contains durable repo-wide engineering rules and defaults.
- `specs/` contains canonical technical contracts and workflows.
- `design/` contains architecture, data, components, screens, and offline behavior.
- `how-to/` contains maintained procedures with prerequisites and verification steps.
- `reference/` contains short Peated-specific references. Do not copy upstream API documentation into the repo.
- `notes/` contains temporary planning or status material. Mark retained notes as active or archived.

## Authoring Rules

- Write for normal humans. Use short sentences, active voice, consistent terms, and one idea per sentence.
- Use kebab-case filenames and clear H1 titles.
- State the purpose near the start. Add `Status: active`, `draft`, or `archived` when lifecycle is not obvious.
- Link cross-repo files with `@` notation, such as `@docs/specs/openapi-workflow.md`.
- Include minimal runnable examples. Prefer a maintained command over a copied command sequence.
- Put feature-specific invariants in the feature or owning module documentation, not in repo-wide policy.
- Update or remove outdated documentation in the same change that makes it stale.
- Delete completed plans and copied upstream references. Link to maintained upstream documentation instead.

## Policy Documents

- Use a policy only for a rule that applies across packages or features.
- Keep policies short. State intent, the default, and real exceptions.
- Do not put plans, rollout status, test inventories, or copied schemas in policies.
- Update `docs/policies/README.md` when adding, renaming, or removing a policy.

## Review

- Verify paths, commands, target names, simulator names, and tool versions.
- Review documentation like code. Confirm that examples match current public interfaces.
- Use screenshots only when they clarify a non-obvious user or development workflow.
