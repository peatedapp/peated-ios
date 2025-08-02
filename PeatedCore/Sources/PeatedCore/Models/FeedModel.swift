import Foundation
import PeatedAPI

public enum FeedType: String, CaseIterable, Sendable {
  case friends = "friends"
  case personal = "self"
  case global = "global"
  
  public var displayName: String {
    switch self {
    case .friends: return "Friends"
    case .personal: return "You"
    case .global: return "Global"
    }
  }
}

@Observable
@MainActor
public class FeedModel {
  public private(set) var tastings: [TastingFeedItem] = []
  public private(set) var isLoading = false
  public private(set) var isSwitchingFeed = false
  public private(set) var error: Error?
  public private(set) var hasMore = true
  public var selectedFeedType: FeedType = .friends
  
  private var cursor: String?
  private let feedRepository: FeedRepository
  
  // Cache for each feed type
  private struct FeedCache {
    var tastings: [TastingFeedItem] = []
    var cursor: String?
    var hasMore: Bool = true
    var lastUpdated: Date?
    
    var isExpired: Bool {
      guard let lastUpdated = lastUpdated else { return true }
      // Cache expires after 5 minutes
      return Date().timeIntervalSince(lastUpdated) > 300
    }
  }
  
  private var feedCaches: [FeedType: FeedCache] = [:]
  
  public init(feedRepository: FeedRepository? = nil) {
    self.feedRepository = feedRepository ?? FeedRepository()
  }
  
  public func loadFeed(refresh: Bool = false) async {
    if isLoading { return }
    
    if refresh {
      cursor = nil
      hasMore = true
    }
    
    isLoading = true
    error = nil
    
    do {
      let feedPage: FeedPage
      
      if refresh {
        feedPage = try await feedRepository.refreshFeed(type: selectedFeedType)
        tastings = feedPage.tastings
      } else {
        feedPage = try await feedRepository.getFeed(
          type: selectedFeedType,
          cursor: cursor,
          limit: 20
        )
        tastings.append(contentsOf: feedPage.tastings)
      }
      
      cursor = feedPage.cursor
      hasMore = feedPage.hasMore
      
      // Update cache for current feed type
      feedCaches[selectedFeedType] = FeedCache(
        tastings: tastings,
        cursor: cursor,
        hasMore: hasMore,
        lastUpdated: Date()
      )
    } catch {
      self.error = error
      print("Failed to load feed: \(error)")
    }
    
    isLoading = false
  }
  
  public func switchFeedType(_ type: FeedType) async {
    selectedFeedType = type
    
    // Check if we have cached data for this feed type
    if let cache = feedCaches[type], !cache.isExpired {
      // Use cached data immediately
      tastings = cache.tastings
      cursor = cache.cursor
      hasMore = cache.hasMore
      error = nil
      
      // Optionally refresh in background if cache is getting old (> 2 minutes)
      if let lastUpdated = cache.lastUpdated,
         Date().timeIntervalSince(lastUpdated) > 120 {
        Task { @MainActor in
          await loadFeed(refresh: true)
        }
      }
    } else {
      // No cache or expired, show loading state
      isSwitchingFeed = true
      tastings = []
      cursor = nil
      hasMore = true
      error = nil
      
      await loadFeed(refresh: true)
      
      isSwitchingFeed = false
    }
  }
  
  public func loadMoreIfNeeded(currentItem: TastingFeedItem) async {
    guard let lastItem = tastings.last,
          lastItem.id == currentItem.id,
          hasMore,
          !isLoading else { return }
    
    await loadFeed(refresh: false)
  }
  
  public func refreshCurrentFeed() async {
    // Clear current cache for this feed type to force fresh data
    feedCaches[selectedFeedType] = nil
    
    // Reset state
    cursor = nil
    hasMore = true
    error = nil
    
    // Load fresh data
    await loadFeed(refresh: true)
  }
}