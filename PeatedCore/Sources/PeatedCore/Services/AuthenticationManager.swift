import Foundation
import GoogleSignIn
import HTTPTypes
import PeatedAPI
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

public final class AuthenticationManager: ObservableObject, @unchecked Sendable {
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
            let presentingViewController = await MainActor.run {
                getRootViewController()
            }

            guard let viewController = presentingViewController else {
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

    public func register(username: String, email: String, password: String,
                         tosAccepted: Bool = true) async throws -> User {
        isLoading = true
        error = nil

        do {
            let client = await apiClient.generatedClient

            let body = Operations.register.Input.Body.json(
                .init(username: username, email: email, password: password, tosAccepted: tosAccepted)
            )

            let response = try await client.register(body: body)

            guard case let .ok(okResponse) = response else {
                throw await Self.registrationFailure(response)
            }
            guard case let .json(jsonPayload) = okResponse.body else {
                throw AuthError.invalidResponse
            }
            if let accessToken = jsonPayload.accessToken {
                try keychain.saveToken(accessToken)
            }

            let apiUser = jsonPayload.user
            var user = User(from: apiUser)

            // Enrich with stats similar to login flow
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
                // Non-fatal
                Telemetry.capture(error, feature: "auth", operation: "load_user_details")
            }

            signInProvider = .password
            authState = .authenticated(user)
            isLoading = false
            return user
        } catch {
            captureAuthFailure(error, operation: "sign_in")
            self.error = error
            authState = .unauthenticated
            isLoading = false
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
        @MainActor
        private func getRootViewController() -> UIViewController? {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first
            else {
                return nil
            }
            return window.rootViewController
        }
    #else
        @MainActor
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
}

// MARK: - Auth Errors

public enum AuthError: LocalizedError, Equatable {
    case noPresentingViewController
    case noIDToken
    case invalidResponse
    /// The server refused to create the account and said why, for example a
    /// taken username or a password that fails its rules.
    case registrationRejected(String)

    public var errorDescription: String? {
        switch self {
        case .noPresentingViewController:
            "Unable to present sign-in view"
        case .noIDToken:
            "Failed to get ID token from Google"
        case .invalidResponse:
            "Invalid response from server"
        case let .registrationRejected(message):
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
        case .ok:
            return .invalidResponse
        case let .badRequest(failure):
            guard case let .json(payload) = failure.body else { return .invalidResponse }
            switch payload {
            case let .case1(body): return .registrationRejected(body.message)
            case let .case2(body): return .registrationRejected(body.message)
            }
        case let .unauthorized(failure):
            guard case let .json(payload) = failure.body else { return .invalidResponse }
            switch payload {
            case let .case1(body): return .registrationRejected(body.message)
            case let .case2(body): return .registrationRejected(body.message)
            }
        case let .undocumented(_, payload):
            // The generated contract does not list 409 for a taken username or
            // email; the server still answers with its standard error body.
            let message = await serverMessage(from: payload.body)
            return .registrationRejected(message ?? AuthError.invalidResponse.localizedDescription)
        }
    }

    /// Reads the `message` field of a standard server error body.
    private static func serverMessage(from body: HTTPBody?) async -> String? {
        guard let body,
              let data = try? await Data(collecting: body, upTo: 10000),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = object["message"] as? String,
              !message.isEmpty
        else { return nil }
        return message
    }

    private func exchangeGoogleIDTokenForSession(idToken: String) async throws -> User {
        try await exchangeForSession(body: .json(.init(value3: .init(idToken: idToken))))
    }

    /// Sends one `/auth/login` request, stores the returned access token, and
    /// returns the signed-in user with their stats. Callers own `authState`.
    private func exchangeForSession(body: Operations.login.Input.Body) async throws -> User {
        let client = await apiClient.generatedClient
        let response = try await client.login(body: body)

        guard case let .ok(okResponse) = response,
              case let .json(jsonPayload) = okResponse.body
        else {
            throw AuthError.invalidResponse
        }

        if let accessToken = jsonPayload.accessToken {
            try keychain.saveToken(accessToken)
        }

        let apiUser = jsonPayload.user
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
