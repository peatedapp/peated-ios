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

## 4. SwiftUI Button (Recommended)

If you prefer the official SwiftUI button with the correct Google "G" icon and spacing, add the `GoogleSignInSwift` product to the app target:

- Xcode > Project > Package Dependencies > `GoogleSignIn-iOS` > Add Product… > select `GoogleSignInSwift` and add to `Peated` target.

Then use the button in your SwiftUI view (already wired in `Peated/Features/Auth/LoginViewSimple.swift`). It will automatically use `GoogleSignInButton` when the module is present, and fall back to a custom white button otherwise:

```
#if canImport(GoogleSignInSwift)
GoogleSignInButton(scheme: .light, style: .standard, state: isLoading ? .loading : .normal) {
  handleGoogleSignIn()
}
#else
// Fallback button kept in repo
#endif
```

Notes:
- Keep button text “Sign in with Google”.
- Use `.light` scheme on light surfaces; `.dark` if needed on dark.
- Do not tint the Google logo — it renders in original colors.

## 4. Testing

1. Make sure you have a valid Google account
2. The OAuth client should be configured for iOS with bundle ID: com.peated.peated-ios
3. Test both success and error cases

## Authorization Code vs ID Token

Peated's `/auth/login` accepts either:

- Authorization code: send `{"code": "…"}` (value2)
- ID token (default in current app): send `{"idToken": "…"}` (value3)

App behavior:
- If you provide a Web Client ID (`GIDServerClientID`) alongside the iOS Client ID, the app requests a one‑time `serverAuthCode` and sends the code to the API.
- If `GIDServerClientID` is absent, the app sends the Google `idToken`.

How to enable authorization code:
- In Google Cloud Console, create/get an OAuth 2.0 Client ID of type "Web application".
- Add this value to `Info.plist` as `GIDServerClientID`.
- The app already prefers the code flow when this key is present.
