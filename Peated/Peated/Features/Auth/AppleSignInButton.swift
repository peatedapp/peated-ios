import AuthenticationServices
import SwiftUI

/// A "Continue with Apple" button in the same outlined style as the other
/// sign-in methods. It requests the user's name and email and hands back the
/// credential the API exchanges for a session.
///
/// Apple's guidelines allow a custom button when it shows the Apple logo and
/// title in one color at the same size as the neighbouring buttons.
///
/// User cancellation is a normal outcome and never reaches `onCompletion`.
struct AppleSignInButton: View {
    /// One of Apple's approved titles: "Continue with Apple", "Sign in with Apple", or "Sign up with Apple".
    var title = "Continue with Apple"
    let onCompletion: (Result<AppleSignInCredential, Error>) -> Void

    @State private var requester = AuthorizationRequester<AppleSignInCredential>()
    @State private var isRequesting = false

    var body: some View {
        Button(action: requestAuthorization) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: "apple.logo")
            }
        }
        .buttonStyle(.authTonal)
        // The requester supports one authorization at a time.
        .disabled(isRequesting)
        .accessibilityIdentifier("appleSignInButton")
    }

    private func requestAuthorization() {
        isRequesting = true
        Task {
            defer { isRequesting = false }
            do {
                if let credential = try await requester.requestAppleID(scopes: [.fullName, .email]) {
                    onCompletion(.success(credential))
                }
            } catch {
                onCompletion(.failure(error))
            }
        }
    }
}
