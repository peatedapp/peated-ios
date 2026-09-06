# Observability

## Intent

Telemetry supports diagnosis and operations. It is not product behavior and must not weaken privacy or reliability.

## Policy

- Logs describe discrete events and decisions. Spans describe timed work and causal relationships. Sentry issues represent actionable unexpected failures.
- Use stable messages and low-cardinality attributes. Keep occurrence-specific values out of message and operation names.
- Bind useful correlation identifiers at the owning boundary without attaching private content.
- Capture an error once at the boundary that owns the failure. Lower layers return or throw it.
- Expected cancellation, rejected input, offline state, and bounded retry do not create Sentry issues.
- Telemetry failure must not change product behavior.
- Product tests assert user-visible or durable outcomes, not logs, spans, or Sentry calls.
- Follow `data-redaction.md` for every log, breadcrumb, span, error, attachment, screenshot, and view hierarchy.

## Exceptions

Tests for the logging or Sentry adapter may assert provider behavior. Crash handlers may capture and flush an error before process exit.
