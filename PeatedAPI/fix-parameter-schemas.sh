#!/bin/bash
set -e

echo "🔧 Fixing missing parameter schemas..."

# Fix all parameters that are missing schema
jq '
  walk(
    if type == "object" and has("name") and has("in") and (.schema == null) then
      . + {"schema": {"type": "string"}}
    else
      .
    end
  )
' "$1" > "$1.tmp" && mv "$1.tmp" "$1"

echo "✅ Fixed missing parameter schemas"