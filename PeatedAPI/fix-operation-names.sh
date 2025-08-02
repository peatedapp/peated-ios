#!/bin/bash
# Fix operation names to use Swift TitleCase convention
# Converts operation IDs like "auth.login" or "bottles.list" to "authLogin", "bottlesList"

set -e

INPUT_FILE="$1"
OUTPUT_FILE="${2:-$INPUT_FILE}"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <input-openapi.json> [output-openapi.json]"
    exit 1
fi

echo "🔧 Fixing operation names to Swift TitleCase..."

# Create a temporary file
TEMP_FILE=$(mktemp)

# Use jq to transform operationIds
jq '
  # Function to convert to TitleCase
  def toTitleCase:
    # Split by dots, underscores, or hyphens
    split("[._-]"; "") | 
    # Filter out empty strings
    map(select(length > 0)) |
    # Process each part
    to_entries | 
    map(
      if .key == 0 then
        # First word stays lowercase (e.g., "auth" in "authLogin")
        .value
      else
        # Capitalize first letter of subsequent words
        .value | (.[0:1] | ascii_upcase) + .[1:]
      end
    ) | 
    join("");
    
  # Walk through the entire structure
  walk(
    if type == "object" and has("operationId") then
      .operationId |= toTitleCase
    else
      .
    end
  )
' "$INPUT_FILE" > "$TEMP_FILE"

# Move temp file to output
mv "$TEMP_FILE" "$OUTPUT_FILE"

echo "✅ Fixed operation names in $OUTPUT_FILE"
echo "   Examples: auth.login → authLogin, bottles.list → bottlesList"