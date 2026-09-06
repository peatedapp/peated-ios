# Background Work

## Intent

Asynchronous work must respect cancellation, app suspension, process termination, and retry semantics.

## Policy

- Persist an authoritative local change before scheduling follow-up sync or upload work.
- Do not treat an unstructured `Task` as durable work. Persist enough state to resume after process termination.
- Make retryable mutations idempotent. Preserve the logical operation identity across attempts.
- Bound attempts, age, backoff, and continuation depth. Record terminal failure or a safe recovery state.
- Carry small validated identifiers and versions across callbacks. Read the full payload from its owning store.
- Reconcile a previous attempt before redispatching work that may already have succeeded remotely.
- Check cancellation in long-running work and do not convert cancellation into a user-visible error.
- Respect network cost and constrained-network settings for non-essential transfers.
- Background execution time is opportunistic. Do not promise completion that iOS cannot guarantee.

## Exceptions

Pure cache warming, image prefetching, and telemetry may be best-effort when losing the work has no product effect.
