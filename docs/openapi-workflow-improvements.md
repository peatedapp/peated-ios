# OpenAPI Workflow Improvements

## Current Pain Points

1. **Tedious Update Process**: Requires temporarily adding dependencies, running generation, then removing dependencies
2. **Large Generated Files**: 12MB+ of generated code causes slow builds
3. **Build Plugin Issues**: Shows permission dialogs to developers
4. **Manual Process**: Too many steps to update API bindings

## Recommended Solution: Separate PeatedAPI Package

### 1. Create a Dedicated PeatedAPI Package

Create a separate Swift package that contains only the API client code:

```
peated-api/
├── Package.swift
├── Sources/
│   └── PeatedAPI/
│       ├── openapi.json
│       ├── openapi-generator-config.yaml
│       └── Generated/
│           ├── Client.swift
│           └── Types.swift
└── Scripts/
    └── update-api.sh
```

### 2. Package Configuration

```swift
// peated-api/Package.swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PeatedAPI",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PeatedAPI",
            targets: ["PeatedAPI"]
        )
    ],
    dependencies: [
        // Runtime dependencies only
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "PeatedAPI",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession")
            ],
            // Pre-generated files, no build plugin
            exclude: ["openapi.json", "openapi-generator-config.yaml"]
        )
    ]
)
```

### 3. Update Script

```bash
#!/bin/bash
# peated-api/Scripts/update-api.sh
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PACKAGE_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "🔄 Updating Peated API Client..."

# Download spec
echo "📥 Downloading OpenAPI spec..."
curl -o "$PACKAGE_ROOT/Sources/PeatedAPI/openapi.json" https://api.peated.com/spec.json

# Fix OpenAPI version if needed
sed -i '' 's/"openapi": "3.1.1"/"openapi": "3.1.0"/' "$PACKAGE_ROOT/Sources/PeatedAPI/openapi.json"

# Fix operationIds
sed -i '' 's/"operationId": "\([^"]*\)\.\([^"]*\)"/"operationId": "\1_\2"/g' "$PACKAGE_ROOT/Sources/PeatedAPI/openapi.json"

# Generate using global installation
echo "🛠️  Generating API client..."
swift-openapi-generator generate \
    --config "$PACKAGE_ROOT/Sources/PeatedAPI/openapi-generator-config.yaml" \
    --output-directory "$PACKAGE_ROOT/Sources/PeatedAPI/Generated" \
    "$PACKAGE_ROOT/Sources/PeatedAPI/openapi.json"

echo "✅ API client updated!"
```

### 4. Use in Main App

In your main app's Package.swift or Xcode project:

```swift
dependencies: [
    // Local package reference
    .package(path: "../peated-api"),
    // OR if published
    .package(url: "https://github.com/yourusername/PeatedAPI", from: "1.0.0")
]
```

### 5. Benefits of This Approach

1. **Clean Separation**: API code is completely separate from app code
2. **Fast Builds**: No build-time generation, just compile pre-generated code
3. **Version Control**: Can tag API client versions for stability
4. **Easy Updates**: Single script to update API bindings
5. **No Permission Dialogs**: No build plugins needed
6. **Shareable**: Can be used by multiple apps/targets

### 6. Alternative: GitHub Action for Automation

```yaml
# .github/workflows/update-api.yml
name: Update API Client
on:
  workflow_dispatch:
  schedule:
    - cron: '0 0 * * 1' # Weekly on Monday

jobs:
  update:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Generator
        run: brew install swift-openapi-generator
      
      - name: Update API
        run: |
          cd peated-api
          ./Scripts/update-api.sh
      
      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          title: "Update API Client"
          body: "Automated API client update from latest spec"
          branch: update-api-client
```

### 7. Migration Steps

1. Create the new `peated-api` package structure
2. Move generated files to the new package
3. Update PeatedCore to depend on PeatedAPI package
4. Remove swift-openapi-generator from PeatedCore dependencies
5. Test the build

### 8. Advanced: Multiple API Versions

If you need to support multiple API versions:

```
peated-api/
├── Sources/
│   ├── PeatedAPIv1/  # Stable version
│   └── PeatedAPIv2/  # Beta version
```

This allows gradual migration between API versions.

## Conclusion

This separate package approach solves all your pain points:
- ✅ Simple update process (one script)
- ✅ Fast builds (no generation during build)
- ✅ No permission dialogs
- ✅ Better organization
- ✅ Version control for API changes

Most production iOS apps with large OpenAPI specs use this pre-generation approach rather than build-time generation.