# Policies

Policies are durable repo-wide engineering rules and defaults. Executable configuration, generated API contracts, exported types, and tests remain authoritative.

Use a policy when the repository must apply the same rule across packages or features. Put feature architecture and non-obvious feature rules in the owning module or feature documentation. Do not use policies for plans, status notes, TODOs, copied schemas, or test inventories.

Current policies:

- [background-work.md](background-work.md)
- [code-comments.md](code-comments.md)
- [correctness-complexity.md](correctness-complexity.md)
- [data-redaction.md](data-redaction.md)
- [error-handling.md](error-handling.md)
- [interface-design.md](interface-design.md)
- [observability.md](observability.md)
- [runtime-boundaries.md](runtime-boundaries.md)
- [swiftui-accessibility.md](swiftui-accessibility.md)

Keep policies short. State the intent, default, and real exceptions. Update a policy when the repository changes its default. Silence elsewhere does not create an exception.
