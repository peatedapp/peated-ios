import Foundation
import PeatedAPI

public protocol UserRepositoryProtocol {
  func getCurrentUser() async throws -> User
  func getUser(id: String) async throws -> User
  func updateProfile(_ input: UpdateProfileInput) async throws -> User
  func followUser(id: String) async throws
  func unfollowUser(id: String) async throws
}

public struct UpdateProfileInput: Sendable {
  public let displayName: String?
  public let bio: String?
  public let location: String?
  
  public init(displayName: String? = nil, bio: String? = nil, location: String? = nil) {
    self.displayName = displayName
    self.bio = bio
    self.location = location
  }
}

public actor UserRepository: UserRepositoryProtocol, BaseRepositoryProtocol {
  public let apiClient: APIClient
  
  public init(apiClient: APIClient? = nil) {
    self.apiClient = apiClient ?? APIClient(
      serverURL: URL(string: "https://api.peated.com/v1")!
    )
  }
  
  public func getCurrentUser() async throws -> User {
    let client = await self.client
    let response = try await client.getMe()
    
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        var user = User(from: payload.user)
        
        // Fetch additional user details including stats
        do {
          let detailsResponse = try await client.getUser(
            path: .init(user: .init(value1: payload.user.id))
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
      }
    case .unauthorized:
      throw APIError.unauthorized
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
  
  public func getUser(id: String) async throws -> User {
    print("UserRepository.getUser called with id: \(id)")
    let client = await self.client
    
    // Create the user payload
    let userPayload: Operations.getUser.Input.Path.userPayload
    if let userId = Double(id), userId == floor(userId) {
      // Convert to integer to avoid decimal URLs like /users/1.0
      print("Using numeric ID: \(Int(userId))")
      userPayload = .init(value1: Double(Int(userId)))
    } else {
      // Assume it's a username
      print("Using username: \(id)")
      userPayload = .init(value3: id)
    }
    
    print("Making API call to get user...")
    let response = try await client.getUser(
      path: .init(user: userPayload)
    )
    print("API call completed")
    
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        var user = User(
          id: String(Int(payload.id)),
          email: payload.email ?? "",
          username: payload.username,
          verified: payload.verified ?? false,
          admin: payload.admin ?? false,
          mod: payload.mod ?? false
        )
        user.pictureUrl = payload.pictureUrl
        
        // Add stats
        user.tastingsCount = Int(payload.stats.tastings)
        user.bottlesCount = Int(payload.stats.bottles)
        user.collectedCount = Int(payload.stats.collected)
        user.contributionsCount = Int(payload.stats.contributions)
        
        return user
      }
    case .unauthorized:
      throw APIError.unauthorized
    case .notFound:
      throw APIError.notFound
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
  
  public func updateProfile(_ input: UpdateProfileInput) async throws -> User {
    let client = await self.client
    
    // Build the update body - users_update doesn't exist in API, return current user for now
    // TODO: Implement when API supports profile updates
    return try await getCurrentUser()
    
    // Placeholder code to avoid unused parameter warning
    _ = input
  }
  
  public func followUser(id: String) async throws {
    let client = await self.client
    
    guard let userId = Double(id) else {
      throw APIError.requestFailed("Invalid user ID")
    }
    
    let response = try await client.addFriend(
      .init(path: .init(user: userId))
    )
    
    switch response {
    case .ok:
      return
    case .badRequest:
      throw APIError.requestFailed("Cannot follow this user")
    case .unauthorized:
      throw APIError.unauthorized
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
  
  public func unfollowUser(id: String) async throws {
    let client = await self.client
    
    guard let userId = Double(id) else {
      throw APIError.requestFailed("Invalid user ID")
    }
    
    let response = try await client.removeFriend(
      .init(path: .init(user: userId))
    )
    
    switch response {
    case .ok:
      return
    case .unauthorized:
      throw APIError.unauthorized
    case .notFound:
      throw APIError.notFound
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
}