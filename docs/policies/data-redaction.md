# Data Redaction

## Intent

Logs, traces, errors, and operational output contain only the safe metadata needed for diagnosis.

## Policy

- Never record passwords, tokens, cookies, OAuth codes, authorization headers, API keys, signed URLs, or Keychain values.
- Do not record full tasting text, comments, search text, email content, uploaded images, image metadata, unrestricted API bodies, or database values containing user content.
- Do not enable default PII collection. Add a reviewed safe field only when it serves a concrete diagnostic need.
- Prefer stable identifiers, operation names, counts, sizes, status values, durations, and bounded error classifications.
- Use allowlists for Sentry context, breadcrumbs, tags, attachments, and third-party error metadata.
- Keep dynamic values private in unified logging unless the field is explicitly approved as public.
- Screenshots and view hierarchies are disabled by default because they can contain private content.
- Redaction is a backstop. Do not collect unrestricted payloads and rely on later filtering.

## Verification

- Test deterministic safe projections and serialization at telemetry boundaries.
- Do not put raw private content in snapshots, fixtures, or failure attachments.
