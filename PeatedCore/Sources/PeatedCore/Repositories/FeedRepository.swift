import Foundation
import PeatedAPI

public protocol FeedRepositoryProtocol {
  func getFeed(type: FeedType, cursor: String?, limit: Int) async throws -> FeedPage
  func refreshFeed(type: FeedType) async throws -> FeedPage
  func getBottleTastings(bottleId: String, cursor: String?, limit: Int) async throws -> FeedPage
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
    var query = Operations.listTastings.Input.Query()
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
      query.user = Operations.listTastings.Input.Query.userPayload(value1: Double(userId))
    case .global:
      // No additional filtering for global feed
      break
    }
    
    let response = try await client.listTastings(query: query)
    let payload = try response.extractPayload()
    
    let tastings = payload.results.map { item -> TastingFeedItem in
      let t = TastingFeedItem.from(item)
      // Seed cache for referenced entities, including per-user flags
      Task {
        await NormalizedStore.shared.upsert(.user(t.userId), value: User(id: t.userId, email: "", username: t.username))
        let b = item.bottle
        await NormalizedStore.shared.upsert(.bottle(t.bottleId), value: Bottle(
          id: t.bottleId,
          name: t.bottleName, // best effort; fullName expected here
          fullName: t.bottleName,
          brand: Brand(id: "0", name: t.bottleBrandName),
          category: t.bottleCategory,
          imageUrl: t.bottleImageUrl,
          isFavorite: b.isFavorite,
          hasTasted: b.hasTasted
        ))
        // Persist tasting into DB tasting cache for instant detail seeding
        try? await DatabaseManager.shared.cacheTasting(t)
      }
      return t
    }
    
    // Use the cursor from the API response
    let nextCursor: String?
    if let apiCursor = payload.rel.nextCursor {
      nextCursor = String(Int(apiCursor))
    } else {
      nextCursor = nil
    }
    
    // Check if there are more results based on cursor presence
    let hasMore = nextCursor != nil
    
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
  
  public func getEntityTastings(entityId: String, cursor: String? = nil, limit: Int = 20) async throws -> FeedPage {
    let client = await self.client
    
    guard let entityIdDouble = Double(entityId) else {
      throw APIError.requestFailed("Invalid entity ID")
    }
    
    // Create the query
    var query = Operations.listTastings.Input.Query()
    query.entity = entityIdDouble
    query.limit = Double(limit)
    
    if let cursor = cursor {
      query.cursor = Double(cursor)
    }
    
    let response = try await client.listTastings(query: query)
    let payload = try response.extractPayload()
    
    let tastings = payload.results.map { item -> TastingFeedItem in
      let t = TastingFeedItem.from(item)
      Task {
        await NormalizedStore.shared.upsert(.user(t.userId), value: User(id: t.userId, email: "", username: t.username))
        let b = item.bottle
        await NormalizedStore.shared.upsert(.bottle(t.bottleId), value: Bottle(
          id: t.bottleId,
          name: t.bottleName,
          fullName: t.bottleName,
          brand: Brand(id: "0", name: t.bottleBrandName),
          category: t.bottleCategory,
          imageUrl: t.bottleImageUrl,
          isFavorite: b.isFavorite,
          hasTasted: b.hasTasted
        ))
        try? await DatabaseManager.shared.cacheTasting(t)
      }
      return t
    }
    
    // Use the cursor from the API response
    let nextCursor: String?
    if let apiCursor = payload.rel.nextCursor {
      nextCursor = String(Int(apiCursor))
    } else {
      nextCursor = nil
    }
    
    // Check if there are more results based on cursor presence
    let hasMore = nextCursor != nil
    
    return FeedPage(
      tastings: tastings,
      cursor: nextCursor,
      hasMore: hasMore
    )
  }
  
  public func getBottleTastings(bottleId: String, cursor: String?, limit: Int = 20) async throws -> FeedPage {
    let client = await self.client
    
    guard let bottleIdDouble = Double(bottleId) else {
      throw APIError.requestFailed("Invalid bottle ID")
    }
    
    // Build the query parameters
    var query = Operations.listTastings.Input.Query()
    query.bottle = bottleIdDouble
    query.limit = Double(limit)
    
    if let cursor = cursor {
      query.cursor = Double(cursor)
    }
    
    let response = try await client.listTastings(query: query)
    let payload = try response.extractPayload()
    
    let tastings = payload.results.map { item -> TastingFeedItem in
      let t = TastingFeedItem.from(item)
      Task {
        await NormalizedStore.shared.upsert(.user(t.userId), value: User(id: t.userId, email: "", username: t.username))
        let b = item.bottle
        await NormalizedStore.shared.upsert(.bottle(t.bottleId), value: Bottle(
          id: t.bottleId,
          name: t.bottleName,
          fullName: t.bottleName,
          brand: Brand(id: "0", name: t.bottleBrandName),
          category: t.bottleCategory,
          imageUrl: t.bottleImageUrl,
          isFavorite: b.isFavorite,
          hasTasted: b.hasTasted
        ))
        try? await DatabaseManager.shared.cacheTasting(t)
      }
      return t
    }
    
    // Use the cursor from the API response
    let nextCursor: String?
    if let apiCursor = payload.rel.nextCursor {
      nextCursor = String(Int(apiCursor))
    } else {
      nextCursor = nil
    }
    
    // Check if there are more results based on cursor presence
    let hasMore = nextCursor != nil
    
    return FeedPage(
      tastings: tastings,
      cursor: nextCursor,
      hasMore: hasMore
    )
  }
}
