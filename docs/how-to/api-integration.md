# API Integration

This document describes how the Peated iOS app integrates with the backend API.

## OpenAPI Specification

The Peated API is documented using OpenAPI 3.0. The specification is available at:

- **Production**: https://api.peated.com/spec.json

## Generated API Client

We use Apple's [swift-openapi-generator](https://github.com/apple/swift-openapi-generator) to generate a type-safe API client from the OpenAPI specification.

### Updating the API Client

To update the API client with the latest API changes:

```bash
# Preferred entry point from repo root
./Scripts/update-api.sh

# Or from the package directory
cd PeatedAPI && ./update-api.sh
```

The script will:
1. Download the latest OpenAPI spec from `https://api.peated.com/spec.json`
2. Normalize and preprocess the spec (version/nullable/parameter schemas)
3. Generate the client using swift-openapi-generator into `PeatedAPI/Sources/PeatedAPI/Generated/`
4. Build the PeatedAPI target to ensure everything compiles

### Manual Update Process

If you need to update manually:

```bash
# Download the OpenAPI spec
curl -o PeatedAPI/Sources/PeatedAPI/openapi.json https://api.peated.com/spec.json

# Generate the client (manual fallback)
cd PeatedAPI
swift run swift-openapi-generator generate \
  --config Sources/PeatedAPI/openapi-generator-config.yaml \
  --output-directory Sources/PeatedAPI/Generated \
  Sources/PeatedAPI/openapi.json
```

## Authentication

The API supports multiple authentication methods through the `/auth/login` endpoint:

### Email/Password Authentication
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

### Google OAuth Code (Web Flow)
```json
{
  "code": "authorization_code_from_google"
}
```

### Google ID Token (Mobile Flow) 
```json
{
  "idToken": "id_token_from_google_sign_in"
}
```

For iOS, we use the ID token flow as recommended by [Google's iOS backend authentication guide](https://developers.google.com/identity/sign-in/ios/backend-auth).

## Configuration

API configuration is stored in xcconfig files:

- `Configuration/Development.xcconfig` - Development environment settings
- `Configuration/Production.xcconfig` - Production environment settings

Key settings:
- `API_BASE_URL` - The base URL for API requests
- `GOOGLE_CLIENT_ID` - The iOS OAuth client ID for Google Sign-In

## Usage

The generated API client is available in the `PeatedAPI` module:

```swift
import PeatedAPI

// Create client
let client = Client(
    serverURL: try Servers.server1(),
    transport: URLSessionTransport()
)

// Login with Google ID token
let response = try await client.authLogin(
    body: .json(.case3(.init(idToken: idToken)))
)
```

## Error Handling

The API client throws typed errors that can be handled:

```swift
do {
    let response = try await client.authLogin(...)
} catch let error as ClientError {
    // Handle client errors (400-499)
} catch let error as ServerError {
    // Handle server errors (500-599)
}
```
