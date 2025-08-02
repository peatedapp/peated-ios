# Practical OpenAPI Workflow Example

## Quick Start: Separate PeatedAPI Package

### Option 1: Sibling Directory Structure (Recommended)

Create a new package alongside your existing projects:

```
/Users/dcramer/src/
├── peated/              # Backend
├── peated-ios/          # iOS app
└── peated-api-swift/    # NEW: Shared API package
```

### Step 1: Create the Package

```bash
cd /Users/dcramer/src
mkdir peated-api-swift
cd peated-api-swift

# Initialize Swift package
swift package init --type library --name PeatedAPI
```

### Step 2: Set Up Package.swift

```swift
// peated-api-swift/Package.swift
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
            resources: [
                .process("Resources")
            ]
        )
    ]
)
```

### Step 3: Move Generated Files

```bash
# Create directory structure
mkdir -p Sources/PeatedAPI/Generated
mkdir -p Sources/PeatedAPI/Resources

# Copy generated files from PeatedCore
cp /Users/dcramer/src/peated-ios/PeatedCore/Sources/PeatedCore/API/Generated/*.swift \
   Sources/PeatedAPI/Generated/

# Copy OpenAPI spec and config
cp /Users/dcramer/src/peated-ios/PeatedCore/Sources/PeatedCore/API/openapi.json \
   Sources/PeatedAPI/Resources/

cp /Users/dcramer/src/peated-ios/PeatedCore/Sources/PeatedCore/API/openapi-generator-config.yaml \
   Sources/PeatedAPI/
```

### Step 4: Create Update Script

```bash
# peated-api-swift/update-api.sh
#!/bin/bash
set -e

echo "🔄 Updating Peated API Client..."

# Install generator if needed
if ! command -v swift-openapi-generator &> /dev/null; then
    echo "📦 Installing swift-openapi-generator..."
    brew install swift-openapi-generator
fi

# Download latest spec
echo "📥 Downloading OpenAPI spec..."
curl -o Sources/PeatedAPI/Resources/openapi.json https://api.peated.com/spec.json

# Fix OpenAPI version
sed -i '' 's/"openapi": "3.1.1"/"openapi": "3.1.0"/' Sources/PeatedAPI/Resources/openapi.json

# Fix operationIds
sed -i '' 's/"operationId": "\([^"]*\)\.\([^"]*\)"/"operationId": "\1_\2"/g' Sources/PeatedAPI/Resources/openapi.json

# Generate
echo "🛠️  Generating API client..."
swift-openapi-generator generate \
    --config openapi-generator-config.yaml \
    --output-directory Sources/PeatedAPI/Generated \
    Sources/PeatedAPI/Resources/openapi.json

echo "✅ Done! Don't forget to commit the changes."
```

### Step 5: Update PeatedCore Package.swift

Remove the API generation and just reference the new package:

```swift
// PeatedCore/Package.swift
dependencies: [
    // ... other dependencies ...
    
    // Add reference to local API package
    .package(path: "../../peated-api-swift"),
    
    // Remove these (no longer needed):
    // .package(url: "https://github.com/apple/swift-openapi-runtime", ...),
    // .package(url: "https://github.com/apple/swift-openapi-urlsession", ...),
],
targets: [
    .target(
        name: "PeatedCore",
        dependencies: [
            // ... other dependencies ...
            .product(name: "PeatedAPI", package: "peated-api-swift"),
        ]
    )
]
```

### Step 6: Update Imports

In your Swift files:

```swift
// Before
import OpenAPIRuntime
import OpenAPIURLSession

// After
import PeatedAPI
```

## Benefits Achieved

1. **One-Command Updates**: Just run `./update-api.sh`
2. **No Permission Dialogs**: No build plugins
3. **Faster Builds**: Pre-generated code
4. **Clear Separation**: API code isolated from app code
5. **Reusable**: Can be used by multiple targets/apps

## Alternative: Git Submodule

If you want version control separation:

```bash
cd /Users/dcramer/src
# Create as separate repo
git init peated-api-swift
cd peated-api-swift
# ... set up package ...
git add .
git commit -m "Initial API package"

# Add as submodule to iOS project
cd ../peated-ios
git submodule add ../peated-api-swift peated-api
```

## CI/CD Integration

Add to your GitHub Actions:

```yaml
- name: Update API if needed
  run: |
    cd peated-api-swift
    ./update-api.sh
    if ! git diff --quiet; then
      echo "API changes detected"
      # Create PR or commit
    fi
```

This approach has worked well for production apps dealing with large OpenAPI specs!