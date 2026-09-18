# Error Handling

## Intent

Unexpected failures should reach the boundary that owns user recovery and diagnostics.

## Policy

- Let operations that should succeed throw to their caller.
- Catch only to recover, translate an expected failure into a typed domain result, or perform required cleanup.
- A catch that handles an error must complete recovery or rethrow with useful domain context.
- Do not log and rethrow the same failure at several layers.
- Treat cancellation as expected control flow. Preserve `CancellationError` unless the current boundary intentionally converts it.
- Keep best-effort work explicit. If correctness depends on an operation, it is not best-effort.
- User-facing errors state what happened and the next useful action. They do not expose raw provider or server details.

## Exceptions

Optional UI content and cache warming may degrade locally when dropping the failure is part of their contract. Authentication, networking, and offline-sync boundaries may own bounded retry or typed fallback behavior.
