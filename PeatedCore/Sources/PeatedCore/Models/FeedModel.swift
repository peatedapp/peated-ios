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
  public var error: Error?
  public private(set) var hasMore = true
  public var selectedFeedType: FeedType = .friends
  
  private var cursor: String?
  private let feedRepository: FeedRepository
  
  // Track background refresh tasks to prevent race conditions
  private var backgroundRefreshTasks: [FeedType: Task<Void, Never>] = [:]
  
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
    
    var memorySizeBytes: Int {
      // Rough estimate: each TastingFeedItem is ~500 bytes on average
      // (includes strings, dates, optional values, etc.)
      return tastings.count * 500
    }
  }
  
  private var feedCaches: [FeedType: FeedCache] = [:]
  
  // Memory management constants
  private static let maxCacheSizeBytes = 10 * 1024 * 1024 // 10MB total
  private static let maxItemsPerFeed = 500 // Reasonable limit per feed type
  
  private let tastingRepository: TastingRepository
  
  public init(feedRepository: FeedRepository? = nil, tastingRepository: TastingRepository? = nil) {
    self.feedRepository = feedRepository ?? FeedRepository()
    self.tastingRepository = tastingRepository ?? TastingRepository()
  }
  
  // Note: We don't need explicit deinit cleanup because:
  // 1. Tasks are cancelled when switching feeds (see switchFeedType)
  // 2. Tasks check for cancellation regularly
  // 3. When the model is deallocated, any remaining tasks will complete harmlessly
  
  public func loadFeed(refresh: Bool = false) async {
    await loadFeedForType(selectedFeedType, refresh: refresh, updateUI: true)
  }
  
  private func loadFeedForType(_ feedType: FeedType, refresh: Bool = false, updateUI: Bool = false) async {
    // Check for cancellation
    guard !Task.isCancelled else { return }
    
    // Only show loading state if updating UI and we're not already loading
    if updateUI && isLoading { return }
    
    if updateUI {
      if refresh {
        cursor = nil
        hasMore = true
      }
      isLoading = true
      error = nil
    }
    
    do {
      let feedPage: FeedPage
      
      if refresh {
        feedPage = try await feedRepository.refreshFeed(type: feedType)
        if updateUI {
          tastings = feedPage.tastings
        }
      } else {
        // For background loads, we need to get the current cursor from cache
        let currentCursor = updateUI ? cursor : feedCaches[feedType]?.cursor
        
        feedPage = try await feedRepository.getFeed(
          type: feedType,
          cursor: currentCursor,
          limit: 20
        )
        
        if updateUI {
          tastings.append(contentsOf: feedPage.tastings)
        }
      }
      
      // Check for cancellation before updating cache
      guard !Task.isCancelled else { return }
      
      // Update cache for the specific feed type
      if refresh || feedCaches[feedType] == nil {
        // For refresh or new cache, replace entirely
        var newCache = FeedCache(
          tastings: feedPage.tastings,
          cursor: feedPage.cursor,
          hasMore: feedPage.hasMore,
          lastUpdated: Date()
        )
        
        // Apply memory limits to new cache
        newCache = enforceMemoryLimits(for: newCache)
        feedCaches[feedType] = newCache
      } else {
        // For pagination, append to existing cache
        var existingCache = feedCaches[feedType] ?? FeedCache()
        existingCache.tastings.append(contentsOf: feedPage.tastings)
        existingCache.cursor = feedPage.cursor
        existingCache.hasMore = feedPage.hasMore
        existingCache.lastUpdated = Date()
        
        // Apply memory limits after appending
        existingCache = enforceMemoryLimits(for: existingCache)
        feedCaches[feedType] = existingCache
      }
      
      // Perform global cache cleanup if total memory usage is too high
      performGlobalCacheCleanupIfNeeded()
      
      // Update UI state if this is for the current feed and we're updating UI
      if updateUI {
        cursor = feedPage.cursor
        hasMore = feedPage.hasMore
      }
      
      // If this background load was for the currently selected feed, update UI
      if !updateUI && feedType == selectedFeedType {
        tastings = feedCaches[feedType]?.tastings ?? []
        cursor = feedCaches[feedType]?.cursor
        hasMore = feedCaches[feedType]?.hasMore ?? true
      }
      
    } catch {
      // Check for cancellation
      guard !Task.isCancelled else { return }
      
      if updateUI {
        self.error = error
        // IMPORTANT: Don't clear cache on error - preserve stale data
        // The UI should show the error while keeping existing content
      }
    }
    
    if updateUI {
      isLoading = false
    }
    
    // Clean up background task reference
    if !updateUI {
      backgroundRefreshTasks[feedType] = nil
    }
  }
  
  public func switchFeedType(_ type: FeedType) async {
    // Cancel any background refresh task for the feed we're leaving
    if let currentTask = backgroundRefreshTasks[selectedFeedType] {
      currentTask.cancel()
      backgroundRefreshTasks[selectedFeedType] = nil
    }
    
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
        
        // Cancel any existing background task for this feed type
        backgroundRefreshTasks[type]?.cancel()
        
        // Start new background refresh task
        backgroundRefreshTasks[type] = Task { @MainActor in
          // Double-check we're still on the same feed type
          guard selectedFeedType == type else { return }
          
          await loadFeedForType(type, refresh: true)
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
    guard hasMore, !isLoading else { return }
    
    // Find the index of current item
    guard let currentIndex = tastings.firstIndex(where: { $0.id == currentItem.id }) else { return }
    
    // Trigger loading when user reaches 3rd item from the end
    let triggerIndex = max(0, tastings.count - 3)
    
    if currentIndex >= triggerIndex {
      await loadFeed(refresh: false)
    }
  }
  
  public func refreshCurrentFeed() async {
    // Cancel any background refresh for the current feed
    backgroundRefreshTasks[selectedFeedType]?.cancel()
    backgroundRefreshTasks[selectedFeedType] = nil
    
    // Don't clear cache here - preserve it in case refresh fails
    // Cache will be replaced only after successful refresh
    
    // Reset pagination state for fresh load
    cursor = nil
    hasMore = true
    error = nil
    
    // Load fresh data (cache will be updated on success)
    await loadFeed(refresh: true)
  }
  
  // MARK: - Memory Management
  
  /// Enforces memory limits on a single feed cache
  private func enforceMemoryLimits(for cache: FeedCache) -> FeedCache {
    var limitedCache = cache
    
    // Limit by number of items first (most important for performance)
    if limitedCache.tastings.count > Self.maxItemsPerFeed {
      // Keep the most recent items (preserve chronological order)
      limitedCache.tastings = Array(limitedCache.tastings.suffix(Self.maxItemsPerFeed))
      
      // When we truncate, we might not have more items even if the original response said we did
      // This is a conservative approach to prevent endless pagination loops
      if limitedCache.tastings.count < cache.tastings.count {
        limitedCache.hasMore = false
      }
    }
    
    return limitedCache
  }
  
  /// Performs cleanup when total cache memory usage exceeds limits
  private func performGlobalCacheCleanupIfNeeded() {
    let totalMemoryUsage = feedCaches.values.reduce(0) { $0 + $1.memorySizeBytes }
    
    guard totalMemoryUsage > Self.maxCacheSizeBytes else { return }
    
    // Strategy: Remove oldest caches first, but preserve current feed
    let sortedCaches = feedCaches
      .filter { $0.key != selectedFeedType } // Don't remove current feed
      .sorted { (lhs, rhs) in
        // Sort by last updated (oldest first)
        let lhsDate = lhs.value.lastUpdated ?? Date.distantPast
        let rhsDate = rhs.value.lastUpdated ?? Date.distantPast
        return lhsDate < rhsDate
      }
    
    // Remove caches until we're under the limit
    var currentMemoryUsage = totalMemoryUsage
    for (feedType, cache) in sortedCaches {
      guard currentMemoryUsage > Self.maxCacheSizeBytes else { break }
      
      feedCaches.removeValue(forKey: feedType)
      currentMemoryUsage -= cache.memorySizeBytes
      
      print("FeedModel: Evicted cache for \(feedType) feed (freed \(cache.memorySizeBytes) bytes)")
    }
    
    // If we're still over the limit, truncate the current feed cache
    if currentMemoryUsage > Self.maxCacheSizeBytes,
       var currentCache = feedCaches[selectedFeedType],
       currentCache.tastings.count > 50 { // Keep at least 50 items
      
      // Reduce current cache by half
      let targetCount = max(50, currentCache.tastings.count / 2)
      currentCache.tastings = Array(currentCache.tastings.suffix(targetCount))
      feedCaches[selectedFeedType] = currentCache
      
      print("FeedModel: Truncated current feed cache to \(targetCount) items")
    }
  }
  
  /// Returns current memory usage statistics (for debugging/monitoring)
  public var cacheMemoryUsage: (totalBytes: Int, feedCounts: [FeedType: Int]) {
    let totalBytes = feedCaches.values.reduce(0) { $0 + $1.memorySizeBytes }
    let feedCounts = feedCaches.mapValues { $0.tastings.count }
    return (totalBytes, feedCounts)
  }
  
  /// Check if we have any data (cached or current) for the selected feed
  public var hasData: Bool {
    !tastings.isEmpty || feedCaches[selectedFeedType]?.tastings.isEmpty == false
  }
  
  /// Check if we're in an error state with no data to show
  public var isErrorWithNoData: Bool {
    error != nil && tastings.isEmpty
  }
  
  /// Clear the error state
  public func clearError() {
    error = nil
  }
  
  // MARK: - Toast Functionality
  
  /// Toggle toast for a tasting with optimistic UI update and offline support
  public func toggleToast(for tastingId: String) async {
    // Find the tasting in current feed
    guard let tastingIndex = tastings.firstIndex(where: { $0.id == tastingId }) else {
      return
    }
    
    let currentTasting = tastings[tastingIndex]
    let newToastedState = !currentTasting.hasToasted
    let newToastCount = newToastedState ? currentTasting.toastCount + 1 : max(0, currentTasting.toastCount - 1)
    
    // Create updated tasting for optimistic update
    let updatedTasting = TastingFeedItem(
      id: currentTasting.id,
      rating: currentTasting.rating,
      notes: currentTasting.notes,
      servingStyle: currentTasting.servingStyle,
      imageUrl: currentTasting.imageUrl,
      createdAt: currentTasting.createdAt,
      userId: currentTasting.userId,
      username: currentTasting.username,
      userDisplayName: currentTasting.userDisplayName,
      userAvatarUrl: currentTasting.userAvatarUrl,
      bottleId: currentTasting.bottleId,
      bottleName: currentTasting.bottleName,
      bottleBrandName: currentTasting.bottleBrandName,
      bottleCategory: currentTasting.bottleCategory,
      bottleImageUrl: currentTasting.bottleImageUrl,
      toastCount: newToastCount,
      commentCount: currentTasting.commentCount,
      hasToasted: newToastedState,
      tags: currentTasting.tags,
      location: currentTasting.location,
      friendUsernames: currentTasting.friendUsernames
    )
    
    // Optimistic update - immediately update UI
    tastings[tastingIndex] = updatedTasting
    
    // Also update all feed caches that contain this tasting
    for feedType in feedCaches.keys {
      if let cacheIndex = feedCaches[feedType]?.tastings.firstIndex(where: { $0.id == tastingId }) {
        feedCaches[feedType]?.tastings[cacheIndex] = updatedTasting
      }
    }
    
    // Check network status
    if !NetworkMonitor.shared.isConnected {
      // Queue for offline sync
      let operation = OfflineOperation.toggleToast(tastingId: tastingId, isToasted: newToastedState)
      await OfflineQueueManager.shared.queueOperation(operation)
      
      // Show offline notification
      ToastManager.shared.showInfo("Toast will sync when online")
      return
    }
    
    // Perform actual API call in background
    Task {
      do {
        let actualToastedState = try await tastingRepository.toggleToast(tastingId: tastingId)
        
        // Show success toast notification
        if actualToastedState {
          ToastManager.shared.showSuccess("Cheers! 🥃")
        }
        
        // Create the correct tasting state based on API response
        let correctTasting = TastingFeedItem(
          id: currentTasting.id,
          rating: currentTasting.rating,
          notes: currentTasting.notes,
          servingStyle: currentTasting.servingStyle,
          imageUrl: currentTasting.imageUrl,
          createdAt: currentTasting.createdAt,
          userId: currentTasting.userId,
          username: currentTasting.username,
          userDisplayName: currentTasting.userDisplayName,
          userAvatarUrl: currentTasting.userAvatarUrl,
          bottleId: currentTasting.bottleId,
          bottleName: currentTasting.bottleName,
          bottleBrandName: currentTasting.bottleBrandName,
          bottleCategory: currentTasting.bottleCategory,
          bottleImageUrl: currentTasting.bottleImageUrl,
          toastCount: actualToastedState ? currentTasting.toastCount + 1 : max(0, currentTasting.toastCount - 1),
          commentCount: currentTasting.commentCount,
          hasToasted: actualToastedState,
          tags: currentTasting.tags,
          location: currentTasting.location,
          friendUsernames: currentTasting.friendUsernames
        )
        
        // Update UI with correct state if needed
        await MainActor.run {
          if let currentIndex = tastings.firstIndex(where: { $0.id == tastingId }) {
            tastings[currentIndex] = correctTasting
            
            // Also update all feed caches
            for feedType in feedCaches.keys {
              if let cacheIndex = feedCaches[feedType]?.tastings.firstIndex(where: { $0.id == tastingId }) {
                feedCaches[feedType]?.tastings[cacheIndex] = correctTasting
              }
            }
          }
        }
        
      } catch {
        // Check if it's a network error that should be queued
        if isNetworkError(error) {
          // Queue for offline sync
          let operation = OfflineOperation.toggleToast(tastingId: tastingId, isToasted: newToastedState)
          await OfflineQueueManager.shared.queueOperation(operation)
          
          ToastManager.shared.showWarning("Toast queued for sync")
        } else {
          // Revert optimistic update on error
          await MainActor.run {
            if let revertIndex = tastings.firstIndex(where: { $0.id == tastingId }) {
              tastings[revertIndex] = currentTasting
              
              // Also revert in all feed caches
              for feedType in feedCaches.keys {
                if let cacheIndex = feedCaches[feedType]?.tastings.firstIndex(where: { $0.id == tastingId }) {
                  feedCaches[feedType]?.tastings[cacheIndex] = currentTasting
                }
              }
            }
            
            // Don't set general error for toast failures - they're user-specific actions
            // Show specific error message via ToastManager
            if let apiError = error as? APIError,
               case .requestFailed(let message) = apiError,
               message == "Cannot toast this tasting" {
              ToastManager.shared.showError("You can't toast your own tastings")
            } else {
              ToastManager.shared.showError("Failed to update toast")
            }
          }
        }
      }
    }
  }
  
  /// Checks if an error is network-related and should trigger offline queueing
  private func isNetworkError(_ error: Error) -> Bool {
    if error is URLError {
      return true
    }
    
    if let apiError = error as? APIError {
      switch apiError {
      case .networkError, .timeout:
        return true
      default:
        return false
      }
    }
    
    return false
  }
}