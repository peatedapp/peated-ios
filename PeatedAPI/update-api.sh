#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "🔄 Updating Peated API Client..."

# Download latest spec
echo "📥 Downloading OpenAPI spec..."
curl -o Sources/PeatedAPI/openapi.json https://api.peated.com/spec.json

# Fix OpenAPI version if needed
echo "🔧 Fixing OpenAPI version..."
sed -i '' 's/"openapi": "3.1.1"/"openapi": "3.1.0"/' Sources/PeatedAPI/openapi.json

# Fix nullable fields (convert anyOf[type, null] to nullable: true)
echo "🔧 Fixing nullable fields..."
./fix-nullable-fields.sh Sources/PeatedAPI/openapi.json

# Fix missing parameter schemas
echo "🔧 Fixing parameter schemas..."
./fix-parameter-schemas.sh Sources/PeatedAPI/openapi.json

# Note: Operation names are now properly camelCased on the server (as of 2025-08-02)
# The fix-operation-names.sh script is no longer needed and has been retired.
# Server now provides operationIDs like "authLogin", "bottlesList" etc.

# Generate using swift-openapi-generator
echo "🛠️  Generating API client..."

# Check if generator is available
if command -v swift-openapi-generator &> /dev/null; then
    swift-openapi-generator generate \
        --config Sources/PeatedAPI/openapi-generator-config.yaml \
        --output-directory Sources/PeatedAPI/Generated \
        Sources/PeatedAPI/openapi.json
else
    echo "⚠️  swift-openapi-generator not found. Using Swift package..."
    # Run from PeatedAPI package
    swift run swift-openapi-generator generate \
        --config Sources/PeatedAPI/openapi-generator-config.yaml \
        --output-directory Sources/PeatedAPI/Generated \
        Sources/PeatedAPI/openapi.json
fi

echo "✅ API client updated successfully!"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Build to verify: swift build"
echo "3. Commit if everything looks good"