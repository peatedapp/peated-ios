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

# Fix operationIds
echo "🔧 Fixing operationIds..."
sed -i '' 's/"operationId": "\([^"]*\)\.\([^"]*\)"/"operationId": "\1_\2"/g' Sources/PeatedAPI/openapi.json

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
    # Temporarily add to Package.swift and run
    cd ../PeatedCore
    swift run swift-openapi-generator generate \
        --config ../peated-api/Sources/PeatedAPI/openapi-generator-config.yaml \
        --output-directory ../peated-api/Sources/PeatedAPI/Generated \
        ../peated-api/Sources/PeatedAPI/openapi.json
    cd ../peated-api
fi

echo "✅ API client updated successfully!"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Build to verify: swift build"
echo "3. Commit if everything looks good"