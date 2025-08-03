import Foundation
import SQLite

/// Manages caching strategy for the app with stale-while-revalidate pattern
@MainActor
public class CacheManager {
  public static let shared = CacheManager()
  
  private let database = DatabaseManager.shared
  
  // Cache validity durations
  private let feedCacheDuration: TimeInterval = 300 // 5 minutes
  private let tastingDetailCacheDuration: TimeInterval = 600 // 10 minutes
  private let bottleCacheDuration: TimeInterval = 3600 // 1 hour
  private let userCacheDuration: TimeInterval = 1800 // 30 minutes
  
  private init() {}
  
  /// Gets feed data with stale-while-revalidate strategy
  public func getFeedData(
    type: FeedType,
    repository: FeedRepository,
    forceRefresh: Bool = false
  ) async throws -> (data: [TastingFeedItem], isFresh: Bool) {
    // 1. Always return cached data first if available
    let cachedData = try await database.getCachedFeed(type: type)
    let cacheAge = cachedData.lastUpdated.map { Date().timeIntervalSince($0) } ?? .infinity
    let isStale = cacheAge > feedCacheDuration
    
    // 2. Return cached data immediately if not forcing refresh
    if !forceRefresh && !cachedData.items.isEmpty {
      // 3. If stale, trigger background refresh
      if isStale {
        Task {
          try? await refreshFeedInBackground(type: type, repository: repository)
        }
      }
      return (cachedData.items, !isStale)
    }
    
    // 4. If no cache or force refresh, fetch from network
    do {
      let freshData = try await repository.getFeed(type: type, cursor: nil)
      try await database.cacheFeed(type: type, items: freshData.tastings)
      return (freshData.tastings, true)
    } catch {
      // 5. On network error, return stale cache if available
      if !cachedData.items.isEmpty {
        return (cachedData.items, false)
      }
      throw error
    }
  }
  
  /// Gets tasting detail with intelligent caching
  public func getTastingDetail(
    id: String,
    repository: TastingRepository,
    forceRefresh: Bool = false
  ) async throws -> (data: TastingFeedItem, isFresh: Bool) {
    // 1. Check cache first
    if let cached = try await database.getCachedTasting(id: id) {
      let cacheAge = Date().timeIntervalSince(cached.lastUpdated)
      let isStale = cacheAge > tastingDetailCacheDuration
      
      // 2. Return immediately if fresh or not forcing refresh
      if !forceRefresh && !isStale {
        return (cached.tasting, true)
      }
      
      // 3. Return stale data and refresh in background
      if !forceRefresh {
        Task {
          try? await refreshTastingInBackground(id: id, repository: repository)
        }
        return (cached.tasting, false)
      }
    }
    
    // 4. Fetch fresh data
    let fresh = try await repository.getTasting(id: id)
    try await database.cacheTasting(fresh)
    return (fresh, true)
  }
  
  /// Performs optimistic update for toast action
  public func toggleToast(
    tastingId: String,
    repository: TastingRepository
  ) async throws -> Bool {
    // 1. Update cache optimistically
    guard let cached = try await database.getCachedTasting(id: tastingId) else {
      throw CacheError.notFound
    }
    
    let originalTasting = cached.tasting
    let newToastState = !originalTasting.hasToasted
    let newToastCount = newToastState ? originalTasting.toastCount + 1 : max(0, originalTasting.toastCount - 1)
    
    // Create updated tasting
    let updatedTasting = TastingFeedItem(
      id: originalTasting.id,
      rating: originalTasting.rating,
      notes: originalTasting.notes,
      servingStyle: originalTasting.servingStyle,
      imageUrl: originalTasting.imageUrl,
      createdAt: originalTasting.createdAt,
      userId: originalTasting.userId,
      username: originalTasting.username,
      userDisplayName: originalTasting.userDisplayName,
      userAvatarUrl: originalTasting.userAvatarUrl,
      bottleId: originalTasting.bottleId,
      bottleName: originalTasting.bottleName,
      bottleBrandName: originalTasting.bottleBrandName,
      bottleCategory: originalTasting.bottleCategory,
      bottleImageUrl: originalTasting.bottleImageUrl,
      toastCount: newToastCount,
      commentCount: originalTasting.commentCount,
      hasToasted: newToastState,
      tags: originalTasting.tags,
      location: originalTasting.location,
      friendUsernames: originalTasting.friendUsernames
    )
    
    try await database.updateCachedTasting(updatedTasting)
    
    // 2. Queue network request
    if NetworkMonitor.shared.isConnected {
      do {
        let actualState = try await repository.toggleToast(tastingId: tastingId)
        // Update with server truth
        let serverTasting = TastingFeedItem(
          id: originalTasting.id,
          rating: originalTasting.rating,
          notes: originalTasting.notes,
          servingStyle: originalTasting.servingStyle,
          imageUrl: originalTasting.imageUrl,
          createdAt: originalTasting.createdAt,
          userId: originalTasting.userId,
          username: originalTasting.username,
          userDisplayName: originalTasting.userDisplayName,
          userAvatarUrl: originalTasting.userAvatarUrl,
          bottleId: originalTasting.bottleId,
          bottleName: originalTasting.bottleName,
          bottleBrandName: originalTasting.bottleBrandName,
          bottleCategory: originalTasting.bottleCategory,
          bottleImageUrl: originalTasting.bottleImageUrl,
          toastCount: actualState ? originalTasting.toastCount + 1 : max(0, originalTasting.toastCount - 1),
          commentCount: originalTasting.commentCount,
          hasToasted: actualState,
          tags: originalTasting.tags,
          location: originalTasting.location,
          friendUsernames: originalTasting.friendUsernames
        )
        try await database.updateCachedTasting(serverTasting)
        return actualState
      } catch {
        // 3. Revert on failure
        try await database.updateCachedTasting(originalTasting)
        throw error
      }
    } else {
      // 4. Queue for offline sync
      let operation = OfflineOperation.toggleToast(
        tastingId: tastingId,
        isToasted: newToastState
      )
      await OfflineQueueManager.shared.queueOperation(operation)
      return newToastState
    }
  }
  
  /// Invalidates all caches
  public func invalidateAllCaches() async throws {
    try await database.clearAllCaches()
  }
  
  /// Invalidates specific feed cache
  public func invalidateFeedCache(type: FeedType) async throws {
    try await database.clearFeedCache(type: type)
  }
  
  // MARK: - Private Methods
  
  private func refreshFeedInBackground(
    type: FeedType,
    repository: FeedRepository
  ) async throws {
    do {
      let freshData = try await repository.getFeed(type: type, cursor: nil)
      try await database.cacheFeed(type: type, items: freshData.tastings)
      
      // Post notification for UI updates
      NotificationCenter.default.post(
        name: .feedDataRefreshed,
        object: nil,
        userInfo: ["feedType": type]
      )
    } catch {
      // Log error but don't throw - this is background refresh
      print("Background refresh failed for \(type): \(error)")
    }
  }
  
  private func refreshTastingInBackground(
    id: String,
    repository: TastingRepository
  ) async throws {
    do {
      let fresh = try await repository.getTasting(id: id)
      try await database.cacheTasting(fresh)
      
      // Post notification for UI updates
      NotificationCenter.default.post(
        name: .tastingDataRefreshed,
        object: nil,
        userInfo: ["tastingId": id]
      )
    } catch {
      print("Background refresh failed for tasting \(id): \(error)")
    }
  }
}

// MARK: - Cache Errors

public enum CacheError: LocalizedError {
  case notFound
  case expired
  case invalidData
  
  public var errorDescription: String? {
    switch self {
    case .notFound:
      return "Data not found in cache"
    case .expired:
      return "Cached data has expired"
    case .invalidData:
      return "Invalid data in cache"
    }
  }
}

// MARK: - Notifications

public extension Notification.Name {
  static let feedDataRefreshed = Notification.Name("com.peated.feedDataRefreshed")
  static let tastingDataRefreshed = Notification.Name("com.peated.tastingDataRefreshed")
}

// MARK: - Cache Models

public struct CachedFeed: Sendable {
  public let type: FeedType
  public let items: [TastingFeedItem]
  public let lastUpdated: Date?
  public let cursor: String?
}

public struct CachedTasting: Sendable {
  public var tasting: TastingFeedItem
  public let lastUpdated: Date
}