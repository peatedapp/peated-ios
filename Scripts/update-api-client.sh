#!/bin/bash
set -e

# Update API Client Script
# This script downloads the latest OpenAPI spec and regenerates the client code
# Usage: ./Scripts/update-api-client.sh

echo "🔄 Updating Peated API Client..."

# Change to PeatedCore directory
cd "$(dirname "$0")/../PeatedCore"

# 1. Download the latest OpenAPI spec
echo "📥 Downloading latest OpenAPI spec..."
curl -o Sources/PeatedCore/API/openapi-new.json https://api.peated.com/v1/spec.json

# 2. Validate the downloaded spec
echo "✅ Validating OpenAPI spec..."
if ! jq '.' Sources/PeatedCore/API/openapi-new.json > /dev/null 2>&1; then
    echo "❌ Invalid JSON in downloaded spec"
    rm Sources/PeatedCore/API/openapi-new.json
    exit 1
fi

# 3. Check OpenAPI version and adjust if needed
OPENAPI_VERSION=$(jq -r '.openapi' Sources/PeatedCore/API/openapi-new.json)
if [[ "$OPENAPI_VERSION" == "3.1.1" ]]; then
    echo "⚠️  Converting OpenAPI 3.1.1 to 3.1.0 (generator compatibility)..."
    jq '.openapi = "3.1.0"' Sources/PeatedCore/API/openapi-new.json > Sources/PeatedCore/API/openapi-temp.json
    mv Sources/PeatedCore/API/openapi-temp.json Sources/PeatedCore/API/openapi-new.json
fi

# 4. Backup current spec
echo "💾 Backing up current spec..."
if [ -f Sources/PeatedCore/API/openapi.json ]; then
    cp Sources/PeatedCore/API/openapi.json Sources/PeatedCore/API/openapi-backup.json
fi

# 5. Replace spec
mv Sources/PeatedCore/API/openapi-new.json Sources/PeatedCore/API/openapi.json

# 6. Generate new client code
echo "🔨 Generating API client..."
swift run swift-openapi-generator generate \
    --config Sources/PeatedCore/API/openapi-generator-config.yaml \
    --output-directory Sources/PeatedCore/API/Generated \
    Sources/PeatedCore/API/openapi.json

# 7. Verify the build still works
echo "🏗️  Verifying build..."
if ! swift build; then
    echo "❌ Build failed with new API client"
    if [ -f Sources/PeatedCore/API/openapi-backup.json ]; then
        echo "🔄 Restoring backup..."
        mv Sources/PeatedCore/API/openapi-backup.json Sources/PeatedCore/API/openapi.json
    fi
    exit 1
fi

# 8. Clean up backup
if [ -f Sources/PeatedCore/API/openapi-backup.json ]; then
    rm Sources/PeatedCore/API/openapi-backup.json
fi

echo "✅ API client updated successfully!"
echo ""
echo "Next steps:"
echo "1. Review the changes to Client.swift and Types.swift"
echo "2. Update any code that uses the API if there are breaking changes"
echo "3. Run tests to ensure everything still works"
echo "4. Commit the updated files"