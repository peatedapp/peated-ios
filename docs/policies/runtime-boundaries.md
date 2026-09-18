# Runtime Boundaries

## Intent

Data crossing API, authentication, deep-link, photo, storage, callback, or durable-state boundaries must be validated and owned explicitly.

## Policy

- Parse external and persisted input before passing it to domain code.
- Reject missing required identity, ownership, destination, version, and retry context. Do not infer them from display values or nearby state.
- Keep authentication tokens and credentials in Keychain-owned code. Do not put them in model, UI, logging, or tool input.
- Keep generated OpenAPI and vendor SDK types inside adapters. Downstream code receives Peated-owned domain values.
- Validate deep links and provider callbacks before navigation or mutation.
- Treat photos, filenames, metadata, server responses, cached JSON, and database rows as untrusted input.
- Preserve stable identity and idempotency across offline retries and resumed work.
- Any value needed after suspension, process termination, or background delivery must be persisted before success is reported. In-memory tasks and values are not durable state.

## Exceptions

One-time migrations may repair named legacy state. Keep each migration bounded, idempotent, and separately verified.
