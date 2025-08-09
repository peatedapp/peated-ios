#!/bin/bash

# Script to convert glyph to iOS app icon
# Requires ImageMagick or sips (built-in macOS tool)

SOURCE_IMAGE="/Users/dcramer/src/peated/apps/web/src/assets/glyph.png"
OUTPUT_DIR="/Users/dcramer/src/peated-ios/Peated/Peated/Resources/Assets.xcassets/AppIcon.appiconset"

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image not found at $SOURCE_IMAGE"
    exit 1
fi

# Create the 1024x1024 app icon using sips (built-in macOS tool)
echo "Converting glyph to 1024x1024 app icon..."
sips -z 1024 1024 "$SOURCE_IMAGE" --out "$OUTPUT_DIR/AppIcon.png"

# Update Contents.json to reference the new image
cat > "$OUTPUT_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ App icon has been set up successfully!"
echo "The glyph has been converted to 1024x1024 and added to the asset catalog."
echo "You should see the new icon when you build and run the app."