#!/bin/bash
# Fix nullable fields in OpenAPI spec that use anyOf pattern
# This converts anyOf[string, null] to type: string, nullable: true

set -e

INPUT_FILE="$1"
OUTPUT_FILE="${2:-$INPUT_FILE}"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <input-openapi.json> [output-openapi.json]"
    exit 1
fi

echo "🔧 Fixing nullable fields in OpenAPI spec..."

# Create a temporary file
TEMP_FILE=$(mktemp)

# Use jq to transform the spec
jq '
  walk(
    if type == "object" and has("anyOf") and (.anyOf | length) == 2 and 
       ((.anyOf | map(.type? == "null") | any)) then
      # One of the anyOf items is null, extract the non-null one
      (.anyOf | map(select(.type? != "null"))[0]) + 
      { nullable: true } +
      (. | del(.anyOf) | to_entries | map(select(.key != "anyOf")) | from_entries)
    else
      .
    end
  )
' "$INPUT_FILE" > "$TEMP_FILE"

# Move temp file to output
mv "$TEMP_FILE" "$OUTPUT_FILE"

echo "✅ Fixed nullable fields in $OUTPUT_FILE"
echo "   Converted anyOf[type, null] patterns to type with nullable: true"