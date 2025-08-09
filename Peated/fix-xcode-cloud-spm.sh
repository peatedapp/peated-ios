#!/bin/bash

# Script to fix Xcode Cloud SPM dependency resolution issues

echo "🔧 Fixing Xcode Cloud SPM dependency resolution..."

PROJECT_DIR="/Users/dcramer/src/peated-ios/Peated"
cd "$PROJECT_DIR"

# 1. Remove Package.resolved to force fresh resolution
echo "📦 Removing Package.resolved..."
rm -f Peated.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# 2. Remove DerivedData
echo "🗑️  Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Peated-*

# 3. Remove SPM cache
echo "🧹 Clearing SPM cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm

# 4. Reset packages in the project
echo "♻️  Resetting packages..."
xcodebuild -project Peated.xcodeproj -scheme Peated -resolvePackageDependencies -clonedSourcePackagesDirPath .build

echo "✅ Package reset complete!"
echo ""
echo "Next steps:"
echo "1. Open the project in Xcode"
echo "2. Go to File > Packages > Reset Package Caches"
echo "3. Go to File > Packages > Resolve Package Versions"
echo "4. Commit the new Package.resolved file"
echo "5. Push to trigger Xcode Cloud build"