import Foundation
import SwiftUI
import GoogleSignIn
import PeatedAPI
import HTTPTypes
#if canImport(UIKit)
import UIKit
#endif

public final class AuthenticationManager: ObservableObject, @unchecked Sendable {
  public static let shared = AuthenticationManager()
  
  @Published public private(set) var authState: AuthState = .unknown
  @Published public private(set) var isLoading = false
  @Published public var error: Error?
  @Published public var needsTermsAcceptance = false

  private let apiClient: APIClient
  private let keychain = KeychainService.shared
  private let userRepository: UserRepository
  
  public var isAuthenticated: Bool {
    if case .authenticated = authState {
      return true
    }
    return false
  }
  
  public var currentUser: User? {
    if case .authenticated(let user) = authState {
      return user
    }
    return nil
  }
  
  public init() {
    self.apiClient = APIClient.shared
    self.userRepository = UserRepository(apiClient: apiClient)
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
        // Token might be invalid
        authState = .unauthenticated
      }
    } else {
      // Attempt to restore a previous Google session and exchange for API token
      do {
        let restoredUser = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
        if let idToken = restoredUser.idToken?.tokenString {
          let user = try await exchangeGoogleIDTokenForSession(idToken: idToken)
          authState = .authenticated(user)
          return
        }
      } catch {
        // Ignore restore failures; fall through to unauthenticated
      }
      authState = .unauthenticated
    }
  }
  
  public func login(email: String, password: String) async throws -> User {
    isLoading = true
    error = nil
    
    print("AuthenticationManager: Attempting login for \(email)")
    
    do {
      let client = await apiClient.generatedClient
      
      // Create the request body
      let body = Operations.login.Input.Body.json(
        .init(
          value1: .init(email: email, password: password)
        )
      )
      
      let response = try await client.login(body: body)
      
      // Extract the successful response
      if case .ok(let okResponse) = response,
         case .json(let jsonPayload) = okResponse.body {
        
        // Save tokens
        if let accessToken = jsonPayload.accessToken {
          try keychain.saveToken(accessToken)
        }
        
        // Convert API user to local User
        let apiUser = jsonPayload.user
        var user = User(from: apiUser)
        
        // Fetch additional user details including stats
        do {
          let detailsResponse = try await client.getUser(
            path: .init(user: .init(value1: apiUser.id))
          )
          
          if case .ok(let detailsOk) = detailsResponse,
             case .json(let detailsJson) = detailsOk.body {
            user.tastingsCount = Int(detailsJson.stats.tastings)
            user.bottlesCount = Int(detailsJson.stats.bottles)
            user.collectedCount = Int(detailsJson.stats.collected)
            user.contributionsCount = Int(detailsJson.stats.contributions)
          }
        } catch {
          // Continue without stats if details fail
          print("Failed to fetch user details: \(error)")
        }
        
        // Update auth state
        authState = .authenticated(user)
        isLoading = false
        print("AuthenticationManager: Login successful, authState updated to authenticated")
        return user
      } else {
        throw AuthError.invalidResponse
      }
    } catch {
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
      self.error = AuthError.noPresentingViewController
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
        // Update auth state
        authState = .authenticated(user)
        isLoading = false
        return user
      } else {
        isLoading = false
        throw AuthError.noIDToken
      }
    } catch {
      self.error = error
      authState = .unauthenticated
      isLoading = false
      throw error
    }
    #else
    throw AuthError.noPresentingViewController
    #endif
  }

  public func register(username: String, email: String, password: String, tosAccepted: Bool = true) async throws -> User {
    isLoading = true
    error = nil

    do {
      let client = await apiClient.generatedClient

      let body = Operations.register.Input.Body.json(
        .init(username: username, email: email, password: password, tosAccepted: tosAccepted)
      )

      let response = try await client.register(body: body)

      if case .ok(let okResponse) = response,
         case .json(let jsonPayload) = okResponse.body {
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
          if case .ok(let detailsOk) = detailsResponse,
             case .json(let detailsJson) = detailsOk.body {
            user.tastingsCount = Int(detailsJson.stats.tastings)
            user.bottlesCount = Int(detailsJson.stats.bottles)
            user.collectedCount = Int(detailsJson.stats.collected)
            user.contributionsCount = Int(detailsJson.stats.contributions)
          }
        } catch {
          // Non-fatal
          print("Failed to fetch user details after register: \(error)")
        }

        authState = .authenticated(user)
        isLoading = false
        return user
      } else {
        throw AuthError.invalidResponse
      }
    } catch {
      self.error = error
      authState = .unauthenticated
      isLoading = false
      throw error
    }
  }
  
  public func logout() async {
    isLoading = true
    error = nil
    
    do {
      try keychain.deleteToken()
      authState = .unauthenticated
    } catch {
      self.error = error
    }
    
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
      print("Failed to refresh user after accepting terms: \(error)")
    }
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
      print("Failed to refresh user after verify: \(error)")
    }
  }
  
  // MARK: - Password Reset
  public func requestPasswordReset(email: String) async throws {
    let client = await apiClient.generatedClient
    let body = Operations.createPasswordReset.Input.Body.json(.init(email: email))
    _ = try await client.createPasswordReset(body: body)
  }

  public func confirmPasswordReset(token: String, newPassword: String) async throws {
    let client = await apiClient.generatedClient
    let body = Operations.confirmPasswordReset.Input.Body.json(
      .init(token: token, password: newPassword)
    )
    _ = try await client.confirmPasswordReset(body: body)
    // After reset, user is verified; we do not auto-login here (token may not be issued)
  }
  
  // MARK: - Helper Methods
  
  private func configuredClient(with token: String) -> APIClient {
    // The APIClient already handles authentication via AuthMiddleware
    // Just return the existing client
    return apiClient
  }
  
  #if canImport(UIKit)
  @MainActor
  private func getRootViewController() -> UIViewController? {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
      return nil
    }
    return window.rootViewController
  }
  #else
  @MainActor
  private func getRootViewController() -> Any? {
    return nil
  }
  #endif
}

// MARK: - Auth Errors

public enum AuthError: LocalizedError {
  case noPresentingViewController
  case noIDToken
  case invalidResponse
  
  public var errorDescription: String? {
    switch self {
    case .noPresentingViewController:
      return "Unable to present sign-in view"
    case .noIDToken:
      return "Failed to get ID token from Google"
    case .invalidResponse:
      return "Invalid response from server"
    }
  }
}

// MARK: - Private helpers

extension AuthenticationManager {
  private func exchangeGoogleIDTokenForSession(idToken: String) async throws -> User {
    let client = await apiClient.generatedClient
    // Create the request body for Google auth (using idToken)
    let body = Operations.login.Input.Body.json(
      .init(
        value3: .init(idToken: idToken)
      )
    )
    let response = try await client.login(body: body)
    // Extract the successful response
    if case .ok(let okResponse) = response,
       case .json(let jsonPayload) = okResponse.body {
      // Save tokens
      if let accessToken = jsonPayload.accessToken {
        try keychain.saveToken(accessToken)
      }
      // Convert API user to local User
      let apiUser = jsonPayload.user
      var user = User(from: apiUser)
      // Fetch additional user details including stats
      do {
        let detailsResponse = try await client.getUser(
          path: .init(user: .init(value1: apiUser.id))
        )
        if case .ok(let detailsOk) = detailsResponse,
           case .json(let detailsJson) = detailsOk.body {
          user.tastingsCount = Int(detailsJson.stats.tastings)
          user.bottlesCount = Int(detailsJson.stats.bottles)
          user.collectedCount = Int(detailsJson.stats.collected)
          user.contributionsCount = Int(detailsJson.stats.contributions)
        }
      } catch {
        // Continue without stats if details fail
        print("Failed to fetch user details: \(error)")
      }
      return user
    } else {
      throw AuthError.invalidResponse
    }
  }
}
