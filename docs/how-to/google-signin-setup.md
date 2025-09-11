# Google Sign-In Setup for iOS

## 1. Add Google Sign-In SDK via Swift Package Manager

1. Open your project in Xcode
2. File > Add Package Dependencies
3. Enter package URL: `https://github.com/google/GoogleSignIn-iOS`
4. Choose version (latest stable)
5. Add package to your target

## 2. Configure URL Schemes

Already done! We have the URL scheme in Info-Custom.plist:
- `com.googleusercontent.apps.721909483682-j8grt27j4o339je406l8hsq45gapqgkg`

## 3. Required Code Changes

The following files need to be updated after adding the SDK:
- AppDelegate.swift - Configure Google Sign-In
- AuthenticationManager.swift - Implement sign-in flow
- LoginScreen.swift - Remove TODO comments

## 4. Testing

1. Make sure you have a valid Google account
2. The OAuth client should be configured for iOS with bundle ID: com.peated.peated-ios
3. Test both success and error cases