import AuthenticationServices
import UIKit

/// Runs one Sign in with Apple authorization without the system button, for
/// flows where the authorization is a confirmation step rather than a sign-in.
///
/// The caller keeps the requester alive until `request()` returns, because the
/// authorization controller only holds its delegate weakly.
@MainActor
final class AppleAuthorizationRequester: NSObject {
    private var controller: ASAuthorizationController?
    private var continuation: CheckedContinuation<AppleSignInCredential?, Error>?
    /// Captured on the main actor in `request()`; the anchor callback is nonisolated but runs on the main thread.
    private nonisolated(unsafe) var anchor: ASPresentationAnchor?

    /// Presents the Apple sheet and returns the credential, or nil when the user cancels.
    func request() async throws -> AppleSignInCredential? {
        precondition(continuation == nil, "An Apple authorization is already in progress")
        let request = ASAuthorizationAppleIDProvider().createRequest()
        // A confirmation needs only the authorization code; Apple sent the name and email at sign-up.
        request.requestedScopes = []
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        self.controller = controller
        anchor = Self.keyWindow()
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    private func finish(with result: Result<AppleSignInCredential?, Error>) {
        continuation?.resume(with: result)
        continuation = nil
        controller = nil
        anchor = nil
    }

    private static func keyWindow() -> UIWindow {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? scenes.first?.windows.first ?? UIWindow()
    }
}

extension AppleAuthorizationRequester: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        let result = Result { try AppleSignInCredential(authorization: authorization) as AppleSignInCredential? }
        Task { @MainActor in
            finish(with: result)
        }
    }

    nonisolated func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let result: Result<AppleSignInCredential?, Error> =
            (error as? ASAuthorizationError)?.code == .canceled ? .success(nil) : .failure(error)
        Task { @MainActor in
            finish(with: result)
        }
    }
}

extension AppleAuthorizationRequester: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        anchor ?? ASPresentationAnchor()
    }
}
