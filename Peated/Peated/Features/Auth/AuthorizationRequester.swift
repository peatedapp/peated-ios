import AuthenticationServices
import UIKit

/// Runs one AuthenticationServices request, such as Sign in with Apple or a
/// passkey assertion, and returns the decoded credential.
///
/// The caller keeps the requester alive until `request(_:)` returns, because the
/// authorization controller only holds its delegate weakly.
@MainActor
final class AuthorizationRequester<Credential: Sendable>: NSObject, ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {
    /// Runs in the nonisolated delegate callback, before the hop back to the main actor.
    private nonisolated let decode: @Sendable (ASAuthorization) throws -> Credential
    private var controller: ASAuthorizationController?
    private var continuation: CheckedContinuation<Credential?, Error>?
    /// Captured on the main actor in `request(_:)`; the anchor callback is nonisolated but runs on the main thread.
    private nonisolated(unsafe) var anchor: ASPresentationAnchor?

    init(decode: @escaping @Sendable (ASAuthorization) throws -> Credential) {
        self.decode = decode
    }

    /// Presents the system sheet and returns the credential, or nil when the user cancels.
    func request(_ request: ASAuthorizationRequest) async throws -> Credential? {
        precondition(continuation == nil, "An authorization is already in progress")
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

    private func finish(with result: Result<Credential?, Error>) {
        continuation?.resume(with: result)
        continuation = nil
        controller = nil
        anchor = nil
    }

    private static func keyWindow() -> UIWindow {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? scenes.first?.windows.first ?? UIWindow()
    }

    nonisolated func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        let result = Result { try decode(authorization) as Credential? }
        Task { @MainActor in
            finish(with: result)
        }
    }

    nonisolated func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let result: Result<Credential?, Error> =
            (error as? ASAuthorizationError)?.code == .canceled ? .success(nil) : .failure(error)
        Task { @MainActor in
            finish(with: result)
        }
    }

    nonisolated func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        anchor ?? ASPresentationAnchor()
    }
}
