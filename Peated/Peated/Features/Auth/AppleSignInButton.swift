import AuthenticationServices
import SwiftUI

/// The system Sign in with Apple button. It requests the user's name and email
/// and hands back the credential the API exchanges for a session.
///
/// User cancellation is a normal outcome and never reaches `onCompletion`.
struct AppleSignInButton: View {
    let label: SignInWithAppleButton.Label
    let onCompletion: (Result<AppleSignInCredential, Error>) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SignInWithAppleButton(label) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case let .success(authorization):
                onCompletion(Result { try AppleSignInCredential(authorization: authorization) })
            case let .failure(error):
                if Self.isCancellation(error) {
                    return
                }
                onCompletion(.failure(error))
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        // The system control sizes its own text. This matches the neighbouring brand buttons.
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("appleSignInButton")
    }

    private static func isCancellation(_ error: Error) -> Bool {
        (error as? ASAuthorizationError)?.code == .canceled
    }
}
