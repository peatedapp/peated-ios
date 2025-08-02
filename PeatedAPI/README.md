# PeatedAPI

This package contains the auto-generated API client for the Peated iOS app.

## Structure

```
Sources/PeatedAPI/
├── Generated/
│   ├── Client.swift      # Generated API client
│   └── Types.swift       # Generated types (12MB+)
├── openapi.json          # OpenAPI specification
├── openapi-generator-config.yaml
└── Exports.swift         # Re-exports for convenience
```

## Updating the API

When the backend API changes:

```bash
./update-api.sh
```

This script will:
1. Download the latest OpenAPI spec from production
2. Fix any compatibility issues (OpenAPI version, operationIds)
3. Regenerate Client.swift and Types.swift
4. The changes are ready to commit

## Why a Separate Package?

- **Fast builds**: PeatedCore doesn't need to recompile 12MB+ of generated code every time
- **Clean separation**: API code is isolated from business logic
- **Easy updates**: One script to update everything
- **No build plugins**: No permission dialogs for developers

## Usage

In PeatedCore or your iOS app:

```swift
import PeatedAPI

let client = Client(
    serverURL: URL(string: "https://api.peated.com/v1")!,
    transport: URLSessionTransport()
)

let response = try await client.auth_login(...)
```

## Dependencies

- OpenAPIRuntime: Runtime support for generated code
- OpenAPIURLSession: HTTP transport implementation

## Build Times

First build after updating the API will be slow (2-3 minutes) due to the large generated files. Subsequent builds use the cached module and are much faster.