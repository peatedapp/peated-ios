# OpenAPI Workflow

## Overview

Peated iOS uses [swift-openapi-generator](https://github.com/apple/swift-openapi-generator) to generate type-safe API client code from our OpenAPI specification. We use **manual generation** (not the build plugin) for better control and faster builds.

## Why Manual Generation?

While Apple recommends using the build plugin, we chose manual generation because:

1. **Faster builds** - No generation step during every build
2. **Version control** - API changes are visible in pull requests
3. **No permission prompts** - External developers don't see plugin permission dialogs
4. **Explicit updates** - API changes happen when we decide, not automatically
5. **Build stability** - Large specs (ours generates 12MB+ of code) can slow builds significantly

This approach is common in production iOS apps and aligns with industry best practices.

## Updating API Bindings

When the backend API changes, update the client code:

```bash
# Run the update script
./Scripts/update-api-client.sh
```

The script will:
1. Download the latest OpenAPI spec from https://api.peated.com/v1/spec.json
2. Validate the JSON is well-formed
3. Convert OpenAPI 3.1.1 to 3.1.0 if needed (generator quirk)
4. Generate new Client.swift and Types.swift
5. Verify the project still builds
6. Restore the backup if generation fails

## Manual Process (if needed)

If you need to update manually or the script fails:

```bash
# 1. Download the latest spec
curl -o PeatedCore/Sources/PeatedCore/API/openapi.json https://api.peated.com/v1/spec.json

# 2. Fix OpenAPI version if needed (generator only supports 3.1.0)
sed -i '' 's/"openapi":"3.1.1"/"openapi":"3.1.0"/' PeatedCore/Sources/PeatedCore/API/openapi.json

# 3. Generate the client code
cd PeatedCore
swift run swift-openapi-generator generate \
    --config Sources/PeatedCore/API/openapi-generator-config.yaml \
    --output-directory Sources/PeatedCore/API/Generated \
    Sources/PeatedCore/API/openapi.json

# 4. Test the build
swift build
```

## Configuration

The generation is configured in `PeatedCore/Sources/PeatedCore/API/openapi-generator-config.yaml`:

```yaml
generate:
  - types
  - client
accessModifier: public
```

This generates:
- `Types.swift` - All request/response types
- `Client.swift` - The API client implementation

## Working with Generated Code

### Authentication
The API client uses `AuthMiddleware` to automatically inject tokens:

```swift
// Token is handled automatically
let response = try await client.auth_period_me()
```

### Handling Responses
Generated methods return enum-based responses:

```swift
let response = try await client.auth_period_login(body: body)

if case .ok(let okResponse) = response,
   case .json(let jsonPayload) = okResponse.body {
    // Success - use jsonPayload
} else {
    // Handle error cases
}
```

### Common Patterns

1. **User ID is Double**: The API returns user IDs as doubles, convert to String:
   ```swift
   let userId = String(Int(apiUser.id))
   ```

2. **Optional fields**: Many fields are optional, provide defaults:
   ```swift
   let email = apiUser.email ?? ""
   ```

3. **Underscore prefixes**: Reserved words get underscore prefixes:
   ```swift
   let isPrivate = user._private ?? false
   ```

## Troubleshooting

### Build takes forever
The generated files are large (12MB+). This is normal for the first build. Subsequent builds use cached modules.

### "Unsupported document version: 3.1.1"
The generator has a quirk with OpenAPI 3.1.1. The update script handles this automatically, but if doing manually:
```bash
sed -i '' 's/"openapi":"3.1.1"/"openapi":"3.1.0"/' openapi.json
```

### Type mismatches after update
When the API changes, you may need to update your code:
1. Check what changed in the generated Types.swift
2. Update your models to match new field names/types
3. The compiler will guide you to all places that need updates

## Best Practices

1. **Always review generated changes** - Large diffs in Types.swift indicate significant API changes
2. **Update atomically** - Don't commit partial updates; ensure everything builds
3. **Test after updates** - API changes might have semantic differences beyond types
4. **Keep specs versioned** - The openapi.json file should be in version control

## CI/CD Integration

For automated updates in CI:

```yaml
# Example GitHub Action
- name: Update API Client
  run: |
    ./Scripts/update-api-client.sh
    if git diff --quiet; then
      echo "No API changes"
    else
      echo "API changes detected"
      # Create PR with changes
    fi
```

## References

- [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator)
- [Swift OpenAPI Generator Documentation](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation)
- [OpenAPI Specification](https://www.openapis.org/)