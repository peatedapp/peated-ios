#!/bin/bash

# Xcode Cloud post-clone script to fix SPM dependency resolution issues
# This script runs after Xcode Cloud clones your repository

set -e

echo "📦 Running Xcode Cloud post-clone script..."

# Clean any existing SPM caches that might cause conflicts
echo "🧹 Cleaning SPM caches..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData

# Remove Package.resolved to force fresh resolution
echo "♻️  Removing Package.resolved for fresh resolution..."
find . -name "Package.resolved" -delete

# Pre-resolve dependencies with explicit timeout and retry logic
echo "📥 Pre-resolving package dependencies..."
for i in {1..3}; do
    if xcodebuild -resolvePackageDependencies \
        -project "$CI_WORKSPACE/Peated.xcodeproj" \
        -scheme "$CI_XCODEBUILD_SCHEME" \
        -derivedDataPath "$CI_DERIVED_DATA_PATH" \
        -clonedSourcePackagesDirPath "$CI_WORKSPACE/.build" \
        2>&1 | tee resolve.log; then
        echo "✅ Package resolution succeeded on attempt $i"
        break
    else
        echo "⚠️  Package resolution failed on attempt $i"
        if [ $i -eq 3 ]; then
            echo "❌ Package resolution failed after 3 attempts"
            cat resolve.log
            exit 1
        fi
        echo "🔄 Retrying in 5 seconds..."
        sleep 5
    fi
done

echo "✅ Post-clone script completed successfully"