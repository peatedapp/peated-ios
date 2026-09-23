# Sign in with Apple Setup

The app offers Sign in with Apple beside Google and email sign-in, as App Store Review Guideline 4.8 requires when a third-party login is offered.

## How it works

1. `AppleSignInButton` presents the system authorization sheet and requests the user's name and email.
2. `AppleSignInCredential` extracts the identity token (a JWT) and the formatted name. Apple sends the name only on the first authorization for that Apple ID.
3. `AuthenticationManager.loginWithApple` posts `{"appleIdentityToken": "...", "fullName": "..."}` to `POST /auth/login` and stores the returned session like every other sign-in.

The server verifies the token against Apple's public keys and requires the token audience to match the app bundle ID `com.peated.Peated`. It links the Apple identity to an existing verified account with the same email, or creates a new account and uses `fullName` to pick a username. Apple relay addresses are treated as ordinary emails.

## Configuration

- `Peated/Peated/Peated.entitlements` declares `com.apple.developer.applesignin`. The App ID `com.peated.Peated` in the developer portal must have the Sign in with Apple capability enabled. Enable it by hand under Identifiers. Xcode Cloud cannot add it and the release export fails with `Automatic signing cannot update bundle identifier` until it is on.
- The server revokes the Apple grant during account deletion with a Sign in with Apple key from the portal's Keys page, tied to the same App ID. Set `APPLE_TEAM_ID`, `APPLE_KEY_ID`, and `APPLE_PRIVATE_KEY` on the server. Login works without them; only revocation needs them.
- No client identifiers or secrets are needed on the device. The server accepts the bundle ID by default and reads `APPLE_CLIENT_IDS` for any other audience.
- Sign out clears the stored session token. The app does not track Apple credential revocation.
- `AuthenticationManager.signInProvider` records on the device which method created the session. When it is Apple, account deletion runs a fresh authorization through `AppleAuthorizationRequester` and sends its `authorizationCode` with `DELETE /users/me`, so the server can revoke the Apple grant as Apple requires. Without a code the deletion still goes through and the grant stays until the member removes it in their Apple ID settings. Sessions created before this record existed have no provider and skip the Apple step.

## Testing

Sign in with Apple needs a device or simulator signed in to an Apple ID. Check both the first authorization, which sends a name, and a repeat authorization, which does not. Cancelling the sheet closes it without an error alert.
