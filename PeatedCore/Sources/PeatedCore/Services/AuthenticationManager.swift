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
  
  private let apiClient: APIClient
  private let keychain = KeychainService.shared
  
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
    self.apiClient = APIClient(
      serverURL: URL(string: "https://api.peated.com/v1")!
    )
  }
  
  // MARK: - Public Methods
  
  public func checkAuthStatus() async {
    if keychain.hasToken {
      do {
        // Try to fetch the current user profile
        _ = try keychain.getToken()
        
        // Token is already configured via AuthMiddleware
        let client = await apiClient.generatedClient
        let response = try await client.auth_me()
        
        // Extract the user from the response
        if case .ok(let okResponse) = response,
           case .json(let jsonPayload) = okResponse.body {
          var user = User(
            id: jsonPayload.user.id,
            email: jsonPayload.user.email,
            username: jsonPayload.user.username,
            verified: jsonPayload.user.verified,
            admin: jsonPayload.user.admin,
            mod: jsonPayload.user.mod
          )
          
          // Fetch additional user details including stats
          do {
            let detailsResponse = try await client.users_details(
              path: .init(user: .init(value1: jsonPayload.user.id))
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
          
          print("AuthenticationManager: User authenticated - admin: \(user.admin), mod: \(user.mod)")
          authState = .authenticated(user)
        }
      } catch {
        // Token might be invalid
        authState = .unauthenticated
      }
    } else {
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
      let body = Operations.auth_login.Input.Body.json(
        .init(
          value1: .init(email: email, password: password)
        )
      )
      
      let response = try await client.auth_login(body: body)
      
      // Extract the successful response
      if case .ok(let okResponse) = response,
         case .json(let jsonPayload) = okResponse.body {
        
        // Save tokens
        if let accessToken = jsonPayload.accessToken {
          try keychain.saveToken(accessToken)
        }
        
        // Convert API user to local User
        let apiUser = jsonPayload.user
        var user = User(
          id: apiUser.id,
          email: apiUser.email,
          username: apiUser.username,
          verified: apiUser.verified,
          admin: apiUser.admin,
          mod: apiUser.mod
        )
        
        // Fetch additional user details including stats
        do {
          let detailsResponse = try await client.users_details(
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
        let client = await apiClient.generatedClient
        
        // Create the request body for Google auth (using idToken)
        let body = Operations.auth_login.Input.Body.json(
          .init(
            value3: .init(idToken: idToken)
          )
        )
        
        let response = try await client.auth_login(body: body)
        
        // Extract the successful response
        if case .ok(let okResponse) = response,
           case .json(let jsonPayload) = okResponse.body {
          
          // Save tokens
          if let accessToken = jsonPayload.accessToken {
            try keychain.saveToken(accessToken)
          }
          
          // Convert API user to local User
          let apiUser = jsonPayload.user
          var user = User(
            id: apiUser.id,
            email: apiUser.email,
            username: apiUser.username,
            verified: apiUser.verified,
            admin: apiUser.admin ?? false,
            mod: apiUser.mod ?? false
          )
          
          // Fetch additional user details including stats
          do {
            let detailsResponse = try await client.users_details(
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
          return user
        } else {
          throw AuthError.invalidResponse
        }
      } else {
        isLoading = false
        throw AuthError.noServerAuthCode
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
  case noServerAuthCode
  case invalidResponse
  
  public var errorDescription: String? {
    switch self {
    case .noPresentingViewController:
      return "Unable to present sign-in view"
    case .noServerAuthCode:
      return "Failed to get authorization code from Google"
    case .invalidResponse:
      return "Invalid response from server"
    }
  }
}