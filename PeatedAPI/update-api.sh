#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPOSITORY_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$SCRIPT_DIR"

SPEC_PATH="Sources/PeatedAPI/openapi.json"
TEMP_SPEC="$(mktemp "Sources/PeatedAPI/.openapi.json.XXXXXX")"
TEMP_NORMALIZED="${TEMP_SPEC}.normalized"
# Override to generate from an unreleased spec, e.g. file:///path/to/spec.json.
SPEC_URL="${PEATED_SPEC_URL:-https://api.peated.com/spec.json}"
SWIFT_DOCKER_IMAGE="swift:6.1.2-jammy@sha256:5910655d205a5a54b0b9efdf72c4066a8de1932513fdc81793e2544b5d5a0709"

cleanup() {
    rm -f "$TEMP_SPEC" "$TEMP_NORMALIZED"
}
trap cleanup EXIT

echo "🔄 Updating Peated API Client..."

# Download latest spec
echo "📥 Downloading OpenAPI spec..."
curl --fail --location --show-error --output "$TEMP_SPEC" "$SPEC_URL"

# Normalize fields that swift-openapi-generator cannot represent directly.
echo "🔧 Normalizing OpenAPI compatibility..."
jq '
  (if .openapi == "3.1.1" then .openapi = "3.1.0" else . end)
  | walk(
      if type == "object" and (.properties?.file?.not == {})
      then .properties.file = ((.properties.file | del(.not)) + {"type": "string"})
      # swift-openapi-runtime cannot serialize a deepObject array of objects.
      # The server (oRPC) reads bracket notation, e.g. distillers[0][name]=Ardbeg,
      # so expose these as a form-exploded string map and let callers build the keys.
      elif type == "object" and .in? == "query" and .style? == "deepObject"
        and .schema?.type? == "array" and .schema?.items?.type? == "object"
      then {name, in, required, style: "form", explode: true,
            schema: {type: "object", additionalProperties: {type: "string"}}}
      else .
      end
    )
  # swift-openapi-generator returns text/event-stream bodies as raw bytes and
  # drops their schemas. Keep each event payload as a named component, such
  # as identifyTastingBottleFromPhotoDoneEventData, so callers can decode it.
  | reduce (
      .paths[][]
      | select(type == "object" and has("operationId"))
      | .operationId as $operation
      | .responses[]?.content?["text/event-stream"]?.schema?.oneOf?[]?
      | select(.properties?.event?.const? != null and (.properties?.data // {}) != {})
      | .properties.event.const as $event
      | {
          key: ($operation + ($event[0:1] | ascii_upcase) + $event[1:] + "EventData"),
          value: .properties.data
        }
    ) as $entry (.; .components.schemas[$entry.key] = $entry.value)
' \
    "$TEMP_SPEC" > "$TEMP_NORMALIZED"
mv "$TEMP_NORMALIZED" "$TEMP_SPEC"

# Fix nullable fields (convert anyOf[type, null] to nullable: true)
echo "🔧 Fixing nullable fields..."
./fix-nullable-fields.sh "$TEMP_SPEC"

# Fix missing parameter schemas
echo "🔧 Fixing parameter schemas..."
./fix-parameter-schemas.sh "$TEMP_SPEC"

# Replace the checked-in specification only after download and preprocessing succeed.
mv "$TEMP_SPEC" "$SPEC_PATH"
trap - EXIT

# Note: As of 2025-08-02, server now provides proper camelCase operationIDs
# (e.g., "getAdminQueueInfo", "aiBottleLookup", etc.)

# Generate using swift-openapi-generator
echo "🛠️  Generating API client..."

# Check if generator is available
if command -v swift-openapi-generator >/dev/null 2>&1; then
    swift-openapi-generator generate \
        --config Sources/PeatedAPI/openapi-generator-config.yaml \
        --output-directory Sources/PeatedAPI/Generated \
        "$SPEC_PATH"
elif command -v swift >/dev/null 2>&1; then
    echo "⚠️  swift-openapi-generator not found. Using Swift package..."
    swift run swift-openapi-generator generate \
        --config Sources/PeatedAPI/openapi-generator-config.yaml \
        --output-directory Sources/PeatedAPI/Generated \
        "$SPEC_PATH"
elif command -v docker >/dev/null 2>&1; then
    echo "⚠️  Swift toolchain not found. Using pinned Docker image..."
    docker run --rm \
        --user "$(id -u):$(id -g)" \
        --env HOME=/tmp \
        --volume "$REPOSITORY_ROOT:/work" \
        --workdir /work/PeatedAPI \
        "$SWIFT_DOCKER_IMAGE" \
        swift run swift-openapi-generator generate \
        --config Sources/PeatedAPI/openapi-generator-config.yaml \
        --output-directory Sources/PeatedAPI/Generated \
        "$SPEC_PATH"
else
    echo "error: API generation requires swift-openapi-generator, Swift, or Docker" >&2
    exit 1
fi

echo "✅ API client updated successfully!"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Build to verify: swift build"
echo "3. Commit if everything looks good"
