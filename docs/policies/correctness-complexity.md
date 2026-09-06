# Correctness and Complexity

## Intent

Correct behavior is required. Added complexity must be worth its maintenance cost.

## Policy

- Judge non-trivial changes on correctness, simplicity, understandability, and maintainability.
- Prefer the smallest design that closes the proven failure mode.
- Do not add speculative states, abstractions, retries, fallbacks, configuration, or recovery paths.
- When correctness needs complexity, name the invariant at the owning boundary and keep the implementation local.
- One layer should own each lifecycle change. Other layers should expose narrow capabilities.
- Do not hide required state in ambient singletons, best-effort callbacks, or one-hop wrappers.
- Tests should prove the rule at the highest useful boundary, not every internal step.

## Exceptions

Security, privacy, data-loss, and duplicate-side-effect fixes may temporarily add complexity when no smaller safe design is available. Record the protected invariant and remaining simplification in the pull request.
