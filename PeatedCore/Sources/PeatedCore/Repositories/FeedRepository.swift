import Foundation
import PeatedAPI

public protocol FeedRepositoryProtocol {
  func getFeed(type: FeedType, cursor: String?, limit: Int) async throws -> FeedPage
  func refreshFeed(type: FeedType) async throws -> FeedPage
}

public struct FeedPage: Sendable {
  public let tastings: [TastingFeedItem]
  public let cursor: String?
  public let hasMore: Bool
  
  public init(tastings: [TastingFeedItem], cursor: String?, hasMore: Bool) {
    self.tastings = tastings
    self.cursor = cursor
    self.hasMore = hasMore
  }
}

public actor FeedRepository: FeedRepositoryProtocol, BaseRepositoryProtocol {
  public let apiClient: APIClient
  private let authManager = AuthenticationManager.shared
  
  public init(apiClient: APIClient? = nil) {
    self.apiClient = apiClient ?? APIClient(
      serverURL: URL(string: "https://api.peated.com/v1")!
    )
  }
  
  public func getFeed(type: FeedType, cursor: String?, limit: Int = 20) async throws -> FeedPage {
    let client = await self.client
    
    // Build the query parameters
    var query = Operations.Tastings_list.Input.Query()
    query.limit = Double(limit)
    
    if let cursor = cursor {
      query.cursor = Double(cursor)
    }
    
    // Add feed type filtering
    switch type {
    case .friends:
      // TODO: API doesn't support friends filter yet, using global for now
      break
    case .personal:
      guard let userId = authManager.currentUser?.id else {
        throw APIError.requestFailed("Not authenticated")
      }
      // Use the userPayload union type
      query.user = Operations.Tastings_list.Input.Query.UserPayload(value1: Double(userId))
    case .global:
      // No additional filtering for global feed
      break
    }
    
    let response = try await client.tastings_list(query: query)
    let payload = try response.extractPayload()
    
    let tastings = payload.results.map { TastingFeedItem.from($0) }
    
    // Calculate cursor for next page
    let nextCursor: String?
    if let lastTasting = tastings.last {
      nextCursor = String(Int(lastTasting.createdAt.timeIntervalSince1970))
    } else {
      nextCursor = nil
    }
    
    // Check if there are more results
    let hasMore = tastings.count == limit
    
    return FeedPage(
      tastings: tastings,
      cursor: nextCursor,
      hasMore: hasMore
    )
  }
  
  public func refreshFeed(type: FeedType) async throws -> FeedPage {
    // For refresh, we always start from the beginning
    return try await getFeed(type: type, cursor: nil, limit: 20)
  }
}