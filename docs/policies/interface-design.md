# Interface Design

## Intent

Interfaces expose the smallest useful capability and make ownership and lifecycle clear.

## Policy

- Prefer narrow capability methods over broad dependency bags or raw access to clients and stores.
- Return the smallest useful domain value. Do not expose storage rows, generated API payloads, or vendor SDK types outside their owning adapter.
- Use the same domain noun across models, methods, persisted keys, UI, tests, and documentation.
- Avoid names such as `Data`, `Payload`, `Manager`, and `Handler` unless that shape or role is the actual boundary.
- Keep exported protocols role-shaped and small. Add a protocol only when it represents a real boundary or removes real coupling.
- Avoid wrappers and aliases that only forward arguments. An intermediate layer must enforce a rule, translate a boundary, or own a lifecycle change.
- Search all consumers before changing a shared interface, error contract, schema, persisted representation, or domain term.
- Use a hard cutover unless compatibility is a stated product or storage requirement.

## Exceptions

Test support may expose narrow construction seams while the production interface remains small. Generated and vendor boundaries may retain external names when translation would make the contract less clear.
