# Code Comments

## Intent

Comments explain non-obvious ownership, invariants, and tradeoffs. They do not narrate code.

## Policy

- Major entry points and adapters need a short comment when ownership or failure semantics are not obvious.
- Public Swift interfaces need documentation when the name and type do not make important behavior clear.
- Comment policy-driven behavior, concurrency isolation, persisted formats, security boundaries, and deliberate omissions.
- Keep comments beside the code that enforces the rule.
- Compatibility branches and temporary fallbacks require a concrete removal issue, release, or condition.
- Keep comments short, concrete, and current.

## Exceptions

Do not comment obvious transformations, control flow, or small leaf helpers. Prefer a hard cutover when a compatibility path has no concrete removal condition.
