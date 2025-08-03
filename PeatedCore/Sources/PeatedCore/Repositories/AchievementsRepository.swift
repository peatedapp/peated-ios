import Foundation
import PeatedAPI

public protocol AchievementsRepositoryProtocol {
  func getUserBadges(userId: String) async throws -> [Achievement]
}

public actor AchievementsRepository: AchievementsRepositoryProtocol, BaseRepositoryProtocol {
  public let apiClient: APIClient
  
  public init(apiClient: APIClient? = nil) {
    self.apiClient = apiClient ?? APIClient(
      serverURL: URL(string: "https://api.peated.com/v1")!
    )
  }
  
  public func getUserBadges(userId: String) async throws -> [Achievement] {
    let client = await self.client
    
    // Create the request parameters
    let userPayload: Operations.listUserBadges.Input.Path.userPayload
    if let userIdDouble = Double(userId) {
      // Use numeric ID
      userPayload = .init(value3: userIdDouble)
    } else {
      // Use username string
      userPayload = .init(value2: userId)
    }
    
    let path = Operations.listUserBadges.Input.Path(user: userPayload)
    
    let response = try await client.listUserBadges(
      path: path,
      query: .init(limit: 100) // Get up to 100 badges
    )
    
    let payload = try response.extractPayload()
    return payload.results.map { Achievement(from: $0) }
  }
  
  // Convenience method for getting current user's badges
  public func getCurrentUserBadges() async throws -> [Achievement] {
    let client = await self.client
    
    // Use "me" for current user
    let userPayload = Operations.listUserBadges.Input.Path.userPayload(value2: "me")
    let path = Operations.listUserBadges.Input.Path(user: userPayload)
    
    let response = try await client.listUserBadges(
      path: path,
      query: .init(limit: 100)
    )
    
    let payload = try response.extractPayload()
    return payload.results.map { Achievement(from: $0) }
  }
}

