# Fix URL Scheme Configuration

The app is crashing because the Google Sign-In URL scheme isn't properly configured. Here's how to fix it:

## Option 1: Update Xcode Project Settings (Recommended)

1. Open the project in Xcode
2. Select the peated-ios target
3. Go to the "Info" tab
4. Expand "URL Types"
5. Click the "+" button to add a new URL Type
6. Set URL Schemes to: `com.googleusercontent.apps.721909483682-j8grt27j4o339je406l8hsq45gapqgkg`
7. Leave other fields empty

## Option 2: Use Custom Info.plist

1. In Xcode, select the peated-ios target
2. Go to the "Build Settings" tab
3. Search for "Info.plist File"
4. Change from using auto-generated to: `peated-ios/Info-Custom.plist`

## Verification

After making these changes, the Google Sign-In flow should work without crashing.