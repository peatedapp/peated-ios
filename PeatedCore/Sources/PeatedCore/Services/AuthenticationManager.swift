import Foundation
import GoogleSignIn
import HTTPTypes
import PeatedAPI
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

/// Owns the member's session and publishes it to SwiftUI.
///
/// Main-actor isolated because SwiftUI views observe the `@Published`
/// properties directly and must only see them change on the main thread.
/// Network work still runs off the main thread; each `await` on the API
/// client suspends and the method resumes here to apply the result.
@MainActor
public final class AuthenticationManager: ObservableObject {
    public static let shared = AuthenticationManager()

    @Published public private(set) var authState: AuthState = .unknown {
        didSet {
            // Error reports carry the stable account id only, and only while signed in.
            Telemetry.setUser(id: currentUser?.id)
        }
    }

    @Published public private(set) var isLoading = false
    @Published public var error: Error?
    @Published public var needsTermsAcceptance = false

    private let apiClient: APIClient
    private let keychain = KeychainService.shared
    private let userRepository: any UserRepositoryProtocol
    private let deleteStoredToken: @Sendable () throws -> Void
    private let googleSignOut: @Sendable () -> Void
    private let defaults: UserDefaults
    private static let signInProviderKey = "com.peated.signInProvider"

    /// How the current session was created. Account deletion asks Apple accounts
    /// for a fresh authorization so the server can revoke the Sign in with Apple grant.
    /// This is a device record, cleared on sign out; the API does not report it.
    public private(set) var signInProvider: SignInProvider? {
        get { defaults.string(forKey: Self.signInProviderKey).flatMap(SignInProvider.init(rawValue:)) }
        set { defaults.set(newValue?.rawValue, forKey: Self.signInProviderKey) }
    }

    public var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }

    public var currentUser: User? {
        if case let .authenticated(user) = authState {
            return user
        }
        return nil
    }

    public init(
        apiClient: APIClient = .shared,
        userRepository: (any UserRepositoryProtocol)? = nil,
        deleteStoredToken: @escaping @Sendable () throws -> Void = {
            try KeychainService.shared.deleteToken()
        },
        googleSignOut: @escaping @Sendable () -> Void = {
            GIDSignIn.sharedInstance.signOut()
        },
        defaults: UserDefaults = .standard
    ) {
        self.apiClient = apiClient
        self.userRepository = userRepository ?? UserRepository(apiClient: apiClient)
        self.deleteStoredToken = deleteStoredToken
        self.googleSignOut = googleSignOut
        self.defaults = defaults
    }

    // MARK: - Public Methods

    public func checkAuthStatus() async {
        if keychain.hasToken {
            do {
                // Try to fetch the current user profile
                _ = try keychain.getToken()

                // Token is already configured via AuthMiddleware
                let user = try await userRepository.getCurrentUser()
                print("AuthenticationManager: User authenticated - admin: \(user.admin), mod: \(user.mod)")
                authState = .authenticated(user)
            } catch {
                // An expired token is expected and is dropped by the report classifier.
                Telemetry.capture(error, feature: "auth", operation: "restore_session")
                authState = .unauthenticated
            }
        } else {
            // Attempt to restore a previous Google session and exchange for API token
            do {
                let restoredUser = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                if let idToken = restoredUser.idToken?.tokenString {
                    let user = try await exchangeGoogleIDTokenForSession(idToken: idToken)
                    signInProvider = .google
                    authState = .authenticated(user)
                    return
                }
            } catch {
                // A missing Google session is normal; anything else is reported.
                captureAuthFailure(error, operation: "restore_google_session")
            }
            authState = .unauthenticated
        }
    }

    public func login(email: String, password: String) async throws -> User {
        isLoading = true
        error = nil

        print("AuthenticationManager: Attempting login for \(email)")

        do {
            let user = try await exchangeForSession(
                body: .json(.init(value1: .init(email: email, password: password)))
            )
            signInProvider = .password
            authState = .authenticated(user)
            isLoading = false
            print("AuthenticationManager: Login successful, authState updated to authenticated")
            return user
        } catch {
            captureAuthFailure(error, operation: "sign_in")
            self.error = error
            authState = .unauthenticated
            isLoading = false
            throw error
        }
    }

    public func loginWithGoogle() async throws -> User {
        #if canImport(UIKit)
            guard let viewController = getRootViewController() else {
                error = AuthError.noPresentingViewController
                throw AuthError.noPresentingViewController
            }

            isLoading = true
            error = nil

            do {
                let result = try await GIDSignIn.sharedInstance.signIn(
                    withPresenting: viewController
                )

                // Use ID token (Google's recommended iOS backend auth approach)
                if let idToken = result.user.idToken?.tokenString {
                    let user = try await exchangeGoogleIDTokenForSession(idToken: idToken)
                    signInProvider = .google
                    authState = .authenticated(user)
                    isLoading = false
                    return user
                } else {
                    isLoading = false
                    throw AuthError.noIDToken
                }
            } catch {
                captureAuthFailure(error, operation: "google_sign_in")
                self.error = error
                authState = .unauthenticated
                isLoading = false
                throw error
            }
        #else
            throw AuthError.noPresentingViewController
        #endif
    }

    /// Exchanges a Sign in with Apple identity token for a Peated session.
    ///
    /// The app presents the Apple authorization UI and hands over the identity
    /// token (a JWT whose audience is the app's bundle ID). Apple sends
    /// `fullName` only on the first authorization, and the server uses it to
    /// pick a username when it creates a new account.
    public func loginWithApple(identityToken: String, fullName: String?) async throws -> User {
        isLoading = true
        error = nil

        do {
            let user = try await exchangeForSession(
                body: .json(.init(value4: .init(appleIdentityToken: identityToken, fullName: fullName)))
            )
            signInProvider = .apple
            authState = .authenticated(user)
            isLoading = false
            return user
        } catch {
            captureAuthFailure(error, operation: "apple_sign_in")
            self.error = error
            authState = .unauthenticated
            isLoading = false
            throw error
        }
    }

    /// Signs in with a passkey. `authorize` presents the system passkey sheet for
    /// the server's challenge and returns nil when the user cancels, which makes
    /// this return nil too.
    public func loginWithPasskey(
        authorize: (PasskeySignInChallenge) async throws -> PasskeyAssertion?
    ) async throws -> User? {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let challenge = try await passkeySignInChallenge()
            guard let assertion = try await authorize(challenge) else {
                return nil
            }

            let client = await apiClient.generatedClient
            let response = try await client.passkeyAuthenticateVerify(
                body: .json(.init(response: .init(assertion), signedChallenge: challenge.signedChallenge))
            )
            guard case let .ok(okResponse) = response,
                  case let .json(auth) = okResponse.body
            else {
                throw AuthError.invalidResponse
            }

            let user = try await startSession(with: auth)
            signInProvider = .passkey
            authState = .authenticated(user)
            return user
        } catch {
            captureAuthFailure(error, operation: "passkey_sign_in")
            self.error = error
            authState = .unauthenticated
            throw error
        }
    }

    /// Creates an account whose only sign-in is a new passkey. `authorize`
    /// presents the system sheet that creates the passkey and returns nil when
    /// the user cancels, which makes this return nil too.
    ///
    /// A taken email or username throws `AuthError.registrationConflict`, and
    /// any other refusal throws `AuthError.registrationRejected` with the
    /// server's reason.
    public func registerWithPasskey(
        username: String,
        email: String,
        tosAccepted: Bool,
        authorize: (PasskeyRegistrationChallenge) async throws -> PasskeyRegistration?
    ) async throws -> User? {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let client = await apiClient.generatedClient
            let challengeResponse = try await client.registerChallenge(
                body: .json(.init(username: username, email: email))
            )
            guard case let .ok(challengeOk) = challengeResponse else {
                throw await Self.registrationFailure(challengeResponse)
            }
            let challenge = try Self.registrationChallenge(from: challengeOk.body.json)

            guard let registration = try await authorize(challenge) else {
                return nil
            }

            let response = try await client.register(
                body: .json(.init(
                    username: username,
                    email: email,
                    passkeyResponse: .init(registration),
                    signedChallenge: challenge.signedChallenge,
                    tosAccepted: tosAccepted
                ))
            )
            guard case let .ok(okResponse) = response else {
                throw await Self.registrationFailure(response)
            }
            guard case let .json(auth) = okResponse.body else {
                throw AuthError.invalidResponse
            }

            let user = try await startSession(with: auth)
            signInProvider = .passkey
            authState = .authenticated(user)
            return user
        } catch {
            if !(error is AuthError) {
                captureAuthFailure(error, operation: "passkey_sign_up")
            }
            self.error = error
            authState = .unauthenticated
            throw error
        }
    }

    public func logout() async {
        isLoading = true
        error = nil

        var logoutError: Error?

        do {
            try deleteStoredToken()
        } catch {
            Telemetry.capture(error, feature: "auth", operation: "sign_out")
            logoutError = error
        }

        googleSignOut()
        signInProvider = nil
        needsTermsAcceptance = false
        authState = .unauthenticated
        error = logoutError
        isLoading = false
    }

    // MARK: - Terms of Service

    public func acceptTerms() async throws {
        let client = await apiClient.generatedClient
        _ = try await client.acceptTos()
        // Refresh current user to update TOS acceptance status
        do {
            let user = try await userRepository.getCurrentUser()
            authState = .authenticated(user)
        } catch {
            // Non-fatal
            Telemetry.capture(error, feature: "auth", operation: "refresh_after_terms")
        }
    }

    // MARK: - Account Deletion

    /// Schedules the signed-in member's account for deletion 24 hours out.
    /// The session stays valid until then; `currentUser.deletionScheduledAt` carries the date.
    /// Apple accounts pass a fresh authorization code so the server revokes the Apple grant now.
    public func requestAccountDeletion(appleAuthorizationCode: String? = nil) async throws {
        let user = try await userRepository.requestAccountDeletion(appleAuthorizationCode: appleAuthorizationCode)
        applyDeletionSchedule(from: user)
    }

    public func cancelAccountDeletion() async throws {
        let user = try await userRepository.cancelAccountDeletion()
        applyDeletionSchedule(from: user)
    }

    /// The deletion routes return the member without stats, so only the schedule is taken from them.
    private func applyDeletionSchedule(from fresh: User) {
        authState = .authenticated(currentUser?.withDeletionSchedule(from: fresh) ?? fresh)
    }

    // MARK: - Email Verification

    public func resendVerificationEmail() async throws {
        let client = await apiClient.generatedClient
        _ = try await client.resendVerificationEmail()
    }

    public func verifyEmail(token: String) async throws {
        let client = await apiClient.generatedClient
        let body = Operations.verifyEmail.Input.Body.json(.init(token: token))
        _ = try await client.verifyEmail(body: body)
        // Refresh current user to update verified flag
        do {
            let user = try await userRepository.getCurrentUser()
            authState = .authenticated(user)
        } catch {
            // Non-fatal
            Telemetry.capture(error, feature: "auth", operation: "refresh_after_verify")
        }
    }

    // MARK: - Password Reset

    public func requestPasswordReset(email: String) async throws {
        let client = await apiClient.generatedClient
        let body = Operations.createRecovery.Input.Body.json(.init(email: email))
        _ = try await client.createRecovery(body: body)
    }

    public func confirmPasswordReset(token: String, newPassword: String) async throws {
        let client = await apiClient.generatedClient
        let body = Operations.confirmRecovery.Input.Body.json(
            .init(token: token, password: newPassword)
        )
        _ = try await client.confirmRecovery(body: body)
        // After reset, user is verified; we do not auto-login here (token may not be issued)
    }

    // MARK: - Helper Methods

    private func configuredClient(with _: String) -> APIClient {
        // The APIClient already handles authentication via AuthMiddleware
        // Just return the existing client
        apiClient
    }

    #if canImport(UIKit)
        private func getRootViewController() -> UIViewController? {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first
            else {
                return nil
            }
            return window.rootViewController
        }
    #else
        private func getRootViewController() -> Any? {
            nil
        }
    #endif
}

// MARK: - Sign-in Provider

public enum SignInProvider: String, Sendable {
    case password
    case google
    case apple
    case passkey
}

// MARK: - Auth Errors

public enum AuthError: LocalizedError, Equatable {
    case noPresentingViewController
    case noIDToken
    case invalidResponse
    /// The server refused to create the account and said why.
    case registrationRejected(String)
    /// Another account already uses this email or username.
    case registrationConflict(field: ConflictField, message: String)

    public enum ConflictField: String, Sendable {
        case email
        case username
    }

    public var errorDescription: String? {
        switch self {
        case .noPresentingViewController:
            "Unable to present sign-in view"
        case .noIDToken:
            "Failed to get ID token from Google"
        case .invalidResponse:
            "Invalid response from server"
        case let .registrationRejected(message), let .registrationConflict(_, message):
            message
        }
    }
}

// MARK: - Private helpers

extension AuthenticationManager {
    /// Reports an unexpected sign-in failure. User cancellation and a missing
    /// Google session are normal outcomes and are not reported.
    private func captureAuthFailure(_ error: any Error, operation: String) {
        if let googleError = error as? GIDSignInError,
           googleError.code == .canceled || googleError.code == .hasNoAuthInKeychain {
            return
        }
        Telemetry.capture(error, feature: "auth", operation: operation)
    }

    /// Turns a refused `register` call into the reason the server gave.
    private static func registrationFailure(_ response: Operations.register.Output) async -> AuthError {
        switch response {
        case .ok: .invalidResponse
        case let .badRequest(failure): rejected(try? failure.body.json)
        case let .unauthorized(failure): rejected(try? failure.body.json)
        case let .forbidden(failure): rejected(try? failure.body.json)
        case let .notFound(failure): rejected(try? failure.body.json)
        case let .conflict(failure): rejected(try? failure.body.json)
        case let .contentTooLarge(failure): rejected(try? failure.body.json)
        case let .internalServerError(failure): rejected(try? failure.body.json)
        case let .undocumented(_, payload): await rejection(from: payload.body)
        }
    }

    /// Turns a refused `registerChallenge` call into the reason the server gave.
    /// The server checks for a taken email or username here, before the passkey exists.
    private static func registrationFailure(_ response: Operations.registerChallenge.Output) async -> AuthError {
        switch response {
        case .ok: .invalidResponse
        case let .badRequest(failure): rejected(try? failure.body.json)
        case let .unauthorized(failure): rejected(try? failure.body.json)
        case let .forbidden(failure): rejected(try? failure.body.json)
        case let .notFound(failure): rejected(try? failure.body.json)
        case let .conflict(failure): rejected(try? failure.body.json)
        case let .contentTooLarge(failure): rejected(try? failure.body.json)
        case let .internalServerError(failure): rejected(try? failure.body.json)
        case let .undocumented(_, payload): await rejection(from: payload.body)
        }
    }

    /// Every documented failure body is the standard server error with a
    /// `message`. The generated types differ per status, so the payload is
    /// re-encoded and read once instead of matched type by type.
    private static func rejected(_ payload: (some Encodable)?) -> AuthError {
        guard let payload, let data = try? JSONEncoder().encode(payload) else {
            return .invalidResponse
        }
        return rejection(in: data)
    }

    private static func rejection(from body: HTTPBody?) async -> AuthError {
        guard let body, let data = try? await Data(collecting: body, upTo: 10000) else {
            return rejection(in: Data())
        }
        return rejection(in: data)
    }

    /// Reads a standard server error body. A `CONFLICT` names the taken field
    /// in `data.field`; anything else becomes the server's `message`.
    private static func rejection(in data: Data) -> AuthError {
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let message = (object?["message"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            ?? AuthError.invalidResponse.localizedDescription
        if object?["code"] as? String == "CONFLICT",
           let field = (object?["data"] as? [String: Any])?["field"] as? String,
           let conflictField = AuthError.ConflictField(rawValue: field) {
            return .registrationConflict(field: conflictField, message: message)
        }
        return .registrationRejected(message)
    }

    /// Decodes the base64url fields of a new-account passkey challenge.
    private static func registrationChallenge(
        from payload: Operations.registerChallenge.Output.Ok.Body.jsonPayload
    ) throws -> PasskeyRegistrationChallenge {
        guard let challenge = Data(base64URLEncoded: payload.options.challenge),
              let relyingPartyID = payload.options.rp.id,
              let userID = Data(base64URLEncoded: payload.options.user.id)
        else {
            throw AuthError.invalidResponse
        }
        return PasskeyRegistrationChallenge(
            challenge: challenge,
            relyingPartyID: relyingPartyID,
            userID: userID,
            userName: payload.options.user.name,
            userVerification: payload.options.authenticatorSelection?.userVerification?.rawValue,
            signedChallenge: payload.signedChallenge
        )
    }

    private func exchangeGoogleIDTokenForSession(idToken: String) async throws -> User {
        try await exchangeForSession(body: .json(.init(value3: .init(idToken: idToken))))
    }

    /// Asks the server for a passkey challenge and decodes its base64url fields.
    private func passkeySignInChallenge() async throws -> PasskeySignInChallenge {
        let client = await apiClient.generatedClient
        let response = try await client.passkeyAuthenticateChallenge(body: .json(.init()))
        guard case let .ok(okResponse) = response,
              case let .json(payload) = okResponse.body,
              let challenge = Data(base64URLEncoded: payload.options.challenge),
              let relyingPartyID = payload.options.rpId
        else {
            throw AuthError.invalidResponse
        }

        let allowedCredentialIDs = try (payload.options.allowCredentials ?? []).map { credential in
            guard let id = Data(base64URLEncoded: credential.id) else { throw AuthError.invalidResponse }
            return id
        }
        return PasskeySignInChallenge(
            challenge: challenge,
            relyingPartyID: relyingPartyID,
            allowedCredentialIDs: allowedCredentialIDs,
            userVerification: payload.options.userVerification?.rawValue,
            signedChallenge: payload.signedChallenge
        )
    }

    /// Sends one `/auth/login` request, stores the returned access token, and
    /// returns the signed-in user with their stats. Callers own `authState`.
    private func exchangeForSession(body: Operations.login.Input.Body) async throws -> User {
        let client = await apiClient.generatedClient
        let response = try await client.login(body: body)

        guard case let .ok(okResponse) = response,
              case let .json(auth) = okResponse.body
        else {
            throw AuthError.invalidResponse
        }
        return try await startSession(with: auth)
    }

    /// Stores the access token from a successful sign-in and returns the user
    /// with their stats. Callers own `authState`.
    private func startSession(with auth: Components.Schemas.Auth) async throws -> User {
        let client = await apiClient.generatedClient
        if let accessToken = auth.accessToken {
            try keychain.saveToken(accessToken)
        }

        let apiUser = auth.user
        var user = User(from: apiUser)

        // Fetch additional user details including stats
        do {
            let detailsResponse = try await client.getUser(
                path: .init(user: .init(value1: apiUser.id))
            )
            if case let .ok(detailsOk) = detailsResponse,
               case let .json(detailsJson) = detailsOk.body {
                user.tastingsCount = Int(detailsJson.stats.tastings)
                user.bottlesCount = Int(detailsJson.stats.bottles)
                user.collectedCount = Int(detailsJson.stats.collected)
                user.contributionsCount = Int(detailsJson.stats.contributions)
            }
        } catch {
            // Continue without stats if details fail
            Telemetry.capture(error, feature: "auth", operation: "load_user_details")
        }
        return user
    }
}

private extension Operations.passkeyAuthenticateVerify.Input.Body.jsonPayload.responsePayload {
    /// The WebAuthn JSON form of an assertion from the platform authenticator.
    init(_ assertion: PasskeyAssertion) {
        let credentialID = assertion.credentialID.base64URLEncodedString()
        self.init(
            id: credentialID,
            rawId: credentialID,
            response: .init(
                clientDataJSON: assertion.clientDataJSON.base64URLEncodedString(),
                authenticatorData: assertion.authenticatorData.base64URLEncodedString(),
                signature: assertion.signature.base64URLEncodedString(),
                userHandle: assertion.userHandle?.base64URLEncodedString()
            ),
            authenticatorAttachment: .platform,
            clientExtensionResults: .init(),
            _type: "public-key"
        )
    }
}

private extension Operations.register.Input.Body.jsonPayload.passkeyResponsePayload {
    /// The WebAuthn JSON form of a passkey the platform authenticator just created.
    init(_ registration: PasskeyRegistration) {
        let credentialID = registration.credentialID.base64URLEncodedString()
        self.init(
            id: credentialID,
            rawId: credentialID,
            response: .init(
                clientDataJSON: registration.clientDataJSON.base64URLEncodedString(),
                attestationObject: registration.attestationObject.base64URLEncodedString()
            ),
            authenticatorAttachment: .platform,
            clientExtensionResults: .init(),
            _type: "public-key"
        )
    }
}
