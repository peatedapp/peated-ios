import Foundation
import SQLite

// MARK: - Cache Tables

extension Tables {
  // Feed cache table
  nonisolated(unsafe) static let feedCache = Table("feed_cache")
  
  struct FeedCache {
    nonisolated(unsafe) static let feedType = Expression<String>("feed_type")
    nonisolated(unsafe) static let tastingIds = Expression<String>("tasting_ids") // JSON array
    nonisolated(unsafe) static let cursor = Expression<String?>("cursor")
    nonisolated(unsafe) static let hasMore = Expression<Bool>("has_more")
    nonisolated(unsafe) static let lastUpdated = Expression<Date>("last_updated")
  }
  
  // Tasting cache table
  nonisolated(unsafe) static let tastingCache = Table("tasting_cache")
  
  struct TastingCache {
    nonisolated(unsafe) static let id = Expression<String>("id")
    nonisolated(unsafe) static let data = Expression<Data>("data") // JSON encoded TastingFeedItem
    nonisolated(unsafe) static let lastUpdated = Expression<Date>("last_updated")
  }
}

// MARK: - Cache Operations

extension DatabaseManager {
  
  // MARK: - Setup
  
  func setupCacheTables() throws {
    // Feed cache table
    try connection.run(Tables.feedCache.create(ifNotExists: true) { t in
      t.column(Tables.FeedCache.feedType, primaryKey: true)
      t.column(Tables.FeedCache.tastingIds)
      t.column(Tables.FeedCache.cursor)
      t.column(Tables.FeedCache.hasMore, defaultValue: false)
      t.column(Tables.FeedCache.lastUpdated)
    })
    
    // Tasting cache table
    try connection.run(Tables.tastingCache.create(ifNotExists: true) { t in
      t.column(Tables.TastingCache.id, primaryKey: true)
      t.column(Tables.TastingCache.data)
      t.column(Tables.TastingCache.lastUpdated)
    })
    
    // Create indexes
    try connection.run(Tables.tastingCache.createIndex(
      Tables.TastingCache.lastUpdated,
      ifNotExists: true
    ))
  }
  
  // MARK: - Feed Cache
  
  public func cacheFeed(type: FeedType, items: [TastingFeedItem]) async throws {
    // 1. Cache individual tastings
    for item in items {
      try await cacheTasting(item)
    }
    
    // 2. Cache feed metadata
    let tastingIds = items.map { $0.id }
    let idsJson = try JSONEncoder().encode(tastingIds)
    let idsString = String(data: idsJson, encoding: .utf8)!
    
    let insert = Tables.feedCache.insert(or: .replace,
      Tables.FeedCache.feedType <- type.rawValue,
      Tables.FeedCache.tastingIds <- idsString,
      Tables.FeedCache.cursor <- nil, // TODO: Add cursor support
      Tables.FeedCache.hasMore <- false, // TODO: Add pagination support
      Tables.FeedCache.lastUpdated <- Date()
    )
    
    try connection.run(insert)
  }
  
  public func getCachedFeed(type: FeedType) async throws -> CachedFeed {
    let query = Tables.feedCache
      .filter(Tables.FeedCache.feedType == type.rawValue)
    
    guard let row = try connection.pluck(query) else {
      return CachedFeed(type: type, items: [], lastUpdated: nil, cursor: nil)
    }
    
    // Decode tasting IDs
    let idsJson = row[Tables.FeedCache.tastingIds]
    let ids = try JSONDecoder().decode([String].self, from: idsJson.data(using: .utf8)!)
    
    // Fetch actual tastings
    var items: [TastingFeedItem] = []
    for id in ids {
      if let cached = try await getCachedTasting(id: id) {
        items.append(cached.tasting)
      }
    }
    
    return CachedFeed(
      type: type,
      items: items,
      lastUpdated: row[Tables.FeedCache.lastUpdated],
      cursor: row[Tables.FeedCache.cursor]
    )
  }
  
  public func clearFeedCache(type: FeedType) async throws {
    let delete = Tables.feedCache
      .filter(Tables.FeedCache.feedType == type.rawValue)
      .delete()
    
    try connection.run(delete)
  }
  
  // MARK: - Tasting Cache
  
  public func cacheTasting(_ tasting: TastingFeedItem) async throws {
    let data = try JSONEncoder().encode(tasting)
    
    let insert = Tables.tastingCache.insert(or: .replace,
      Tables.TastingCache.id <- tasting.id,
      Tables.TastingCache.data <- data,
      Tables.TastingCache.lastUpdated <- Date()
    )
    
    try connection.run(insert)
  }
  
  public func getCachedTasting(id: String) async throws -> CachedTasting? {
    let query = Tables.tastingCache
      .filter(Tables.TastingCache.id == id)
    
    guard let row = try connection.pluck(query) else {
      return nil
    }
    
    let tasting = try JSONDecoder().decode(
      TastingFeedItem.self,
      from: row[Tables.TastingCache.data]
    )
    
    return CachedTasting(
      tasting: tasting,
      lastUpdated: row[Tables.TastingCache.lastUpdated]
    )
  }
  
  public func updateCachedTasting(_ tasting: TastingFeedItem) async throws {
    try await cacheTasting(tasting) // insert or replace handles updates
  }
  
  // MARK: - Clear All Caches
  
  public func clearAllCaches() async throws {
    try connection.run(Tables.feedCache.delete())
    try connection.run(Tables.tastingCache.delete())
  }
  
  // MARK: - Cache Statistics
  
  public func getCacheStatistics() async throws -> CacheStatistics {
    let feedCount = try connection.scalar(Tables.feedCache.count)
    let tastingCount = try connection.scalar(Tables.tastingCache.count)
    
    // Calculate total size
    let feedSize = try connection.prepare(
      "SELECT SUM(LENGTH(tasting_ids)) FROM feed_cache"
    ).scalar() as? Int64 ?? 0
    
    let tastingSize = try connection.prepare(
      "SELECT SUM(LENGTH(data)) FROM tasting_cache"
    ).scalar() as? Int64 ?? 0
    
    return CacheStatistics(
      feedEntries: feedCount,
      tastingEntries: tastingCount,
      totalSizeBytes: Int(feedSize + tastingSize)
    )
  }
}

public struct CacheStatistics {
  public let feedEntries: Int
  public let tastingEntries: Int
  public let totalSizeBytes: Int
  
  public var totalSizeMB: Double {
    Double(totalSizeBytes) / 1024 / 1024
  }
}