import Foundation
import PeatedAPI

/// The two feeds the app offers, in tab order. Global is the default, as on the web.
public enum FeedType: String, CaseIterable, Sendable {
    case global
    case friends

    public var displayName: String {
        switch self {
        case .global: "Global"
        case .friends: "Friends"
        }
    }
}

/// Helper class to hold the observer outside of the actor
private final class ObserverHolder: @unchecked Sendable {
    var observer: NSObjectProtocol?
}

@Observable
@MainActor
public class FeedModel {
    public private(set) var entries: [ActivityFeedEntry] = []
    public private(set) var isLoading = false
    public private(set) var isSwitchingFeed = false
    public var error: Error?
    public private(set) var hasMore = true
    public var selectedFeedType: FeedType

    private var cursor: String?
    private let feedRepository: any FeedRepositoryProtocol
    private let cacheManager = CacheManager.shared

    /// Track background refresh tasks to prevent race conditions
    private var backgroundRefreshTasks: [FeedType: Task<Void, Never>] = [:]

    /// Store the observer in a class to avoid actor isolation issues
    private let observerHolder = ObserverHolder()

    /// Cache for each feed type
    private struct FeedCache {
        var entries: [ActivityFeedEntry] = []
        var cursor: String?
        var hasMore: Bool = true
        var lastUpdated: Date?

        var isExpired: Bool {
            guard let lastUpdated else { return true }
            // Cache expires after 5 minutes
            return Date().timeIntervalSince(lastUpdated) > 300
        }

        var memorySizeBytes: Int {
            // Rough estimate: each entry is ~500 bytes on average
            entries.count * 500
        }
    }

    private var feedCaches: [FeedType: FeedCache] = [:]

    // Memory management constants
    private let maxCacheSizeBytes = 10 * 1024 * 1024 // 10MB total
    private let maxItemsPerFeed = 500 // Reasonable limit per feed type

    private let tastingRepository: TastingRepository
    private let selectionStore: any FeedSelectionStore

    public init(
        feedRepository: (any FeedRepositoryProtocol)? = nil,
        tastingRepository: TastingRepository? = nil,
        selectionStore: any FeedSelectionStore = UserDefaultsFeedSelectionStore()
    ) {
        self.feedRepository = feedRepository ?? FeedRepository()
        self.tastingRepository = tastingRepository ?? TastingRepository()
        self.selectionStore = selectionStore
        selectedFeedType = selectionStore.loadSelection() ?? .global

        // Set up notification observer after initialization
        Task { @MainActor in
            self.setupNotificationObserver()
        }
    }

    deinit {
        if let observer = observerHolder.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupNotificationObserver() {
        observerHolder.observer = NotificationCenter.default.addObserver(
            forName: .feedDataRefreshed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                // Extract feedType from notification userInfo in a safe way
                await self.handleFeedRefreshNotification()
            }
        }
    }

    private func handleFeedRefreshNotification() async {
        // This method is called on MainActor, so we can safely access properties
        // Note: We can't access the notification userInfo here due to Sendable constraints
        // When we receive a feed refresh notification (e.g., after creating a tasting),
        // we need to invalidate the cache and fetch fresh data from the API

        // Invalidate current feed cache
        feedCaches[selectedFeedType] = nil

        // Refresh current feed from API
        await refreshCurrentFeed()
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
        if updateUI, isLoading {
            return
        }

        if updateUI {
            if refresh {
                cursor = nil
                hasMore = true
            }
            isLoading = true
            error = nil
        }

        do {
            let feedPage: ActivityPage

            if refresh {
                feedPage = try await feedRepository.refreshActivity(type: feedType)
                if updateUI {
                    entries = feedPage.entries
                }
            } else {
                // For background loads, we need to get the current cursor from cache
                let currentCursor = updateUI ? cursor : feedCaches[feedType]?.cursor

                feedPage = try await feedRepository.getActivity(
                    type: feedType,
                    cursor: currentCursor,
                    limit: 20
                )

                if updateUI {
                    entries.append(contentsOf: feedPage.entries)
                }
            }

            // Check for cancellation before updating cache
            guard !Task.isCancelled else { return }

            // Update cache for the specific feed type
            if refresh || feedCaches[feedType] == nil {
                // For refresh or new cache, replace entirely
                var newCache = FeedCache(
                    entries: feedPage.entries,
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
                existingCache.entries.append(contentsOf: feedPage.entries)
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
                entries = feedCaches[feedType]?.entries ?? []
                cursor = feedCaches[feedType]?.cursor
                hasMore = feedCaches[feedType]?.hasMore ?? false
            }

            // If this background load was for the currently selected feed, update UI
            if !updateUI, feedType == selectedFeedType {
                entries = feedCaches[feedType]?.entries ?? []
                cursor = feedCaches[feedType]?.cursor
                hasMore = feedCaches[feedType]?.hasMore ?? true
            }

        } catch {
            // Check for cancellation
            guard !Task.isCancelled else { return }

            Telemetry.capture(error, feature: "feed", operation: "load")

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
        selectionStore.saveSelection(type)

        // Check if we have cached data for this feed type
        if let cache = feedCaches[type], !cache.isExpired {
            // Use cached data immediately
            entries = cache.entries
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
            entries = []
            cursor = nil
            hasMore = true
            error = nil

            await loadFeed()

            isSwitchingFeed = false
        }
    }

    public func loadMoreIfNeeded(currentEntry: ActivityFeedEntry) async {
        guard hasMore, !isLoading else { return }

        // Find the index of current entry
        guard let currentIndex = entries.firstIndex(where: { $0.id == currentEntry.id }) else { return }

        // Trigger loading when user reaches 3rd entry from the end
        let triggerIndex = max(0, entries.count - 3)

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

    /// Reloads data from cache for the current feed type
    private func reloadFromCache() async {
        guard let cache = feedCaches[selectedFeedType], !cache.entries.isEmpty else {
            return
        }

        // Update UI with cached data
        entries = cache.entries
        cursor = cache.cursor
        hasMore = cache.hasMore
    }

    // MARK: - Memory Management

    /// Enforces memory limits on a single feed cache
    private func enforceMemoryLimits(for cache: FeedCache) -> FeedCache {
        var limitedCache = cache

        // Limit by number of entries first (most important for performance)
        if limitedCache.entries.count > maxItemsPerFeed {
            // Keep the most recent items (preserve chronological order)
            limitedCache.entries = Array(limitedCache.entries.suffix(maxItemsPerFeed))

            // When we truncate, we might not have more items even if the original response said we did
            // This is a conservative approach to prevent endless pagination loops
            if limitedCache.entries.count < cache.entries.count {
                limitedCache.hasMore = false
            }
        }

        return limitedCache
    }

    /// Performs cleanup when total cache memory usage exceeds limits
    private func performGlobalCacheCleanupIfNeeded() {
        let totalMemoryUsage = feedCaches.values.reduce(0) { $0 + $1.memorySizeBytes }

        guard totalMemoryUsage > maxCacheSizeBytes else { return }

        // Strategy: Remove oldest caches first, but preserve current feed
        let sortedCaches = feedCaches
            .filter { $0.key != selectedFeedType } // Don't remove current feed
            .sorted { lhs, rhs in
                // Sort by last updated (oldest first)
                let lhsDate = lhs.value.lastUpdated ?? Date.distantPast
                let rhsDate = rhs.value.lastUpdated ?? Date.distantPast
                return lhsDate < rhsDate
            }

        // Remove caches until we're under the limit
        var currentMemoryUsage = totalMemoryUsage
        for (feedType, cache) in sortedCaches {
            guard currentMemoryUsage > maxCacheSizeBytes else { break }

            feedCaches.removeValue(forKey: feedType)
            currentMemoryUsage -= cache.memorySizeBytes

            print("FeedModel: Evicted cache for \(feedType) feed (freed \(cache.memorySizeBytes) bytes)")
        }

        // If we're still over the limit, truncate the current feed cache
        if currentMemoryUsage > maxCacheSizeBytes,
           var currentCache = feedCaches[selectedFeedType],
           currentCache.entries.count > 50 { // Keep at least 50 items

            // Reduce current cache by half
            let targetCount = max(50, currentCache.entries.count / 2)
            currentCache.entries = Array(currentCache.entries.suffix(targetCount))
            feedCaches[selectedFeedType] = currentCache

            print("FeedModel: Truncated current feed cache to \(targetCount) items")
        }
    }

    /// Returns current memory usage statistics (for debugging/monitoring)
    public var cacheMemoryUsage: (totalBytes: Int, feedCounts: [FeedType: Int]) {
        let totalBytes = feedCaches.values.reduce(0) { $0 + $1.memorySizeBytes }
        let feedCounts = feedCaches.mapValues { $0.entries.count }
        return (totalBytes, feedCounts)
    }

    /// Check if we have any data (cached or current) for the selected feed
    public var hasData: Bool {
        !entries.isEmpty || feedCaches[selectedFeedType]?.entries.isEmpty == false
    }

    /// Check if we're in an error state with no data to show
    public var isErrorWithNoData: Bool {
        error != nil && entries.isEmpty
    }

    /// Clear the error state
    public func clearError() {
        error = nil
    }

    // MARK: - Toast Functionality

    /// Toggle toast for a tasting with optimistic UI update and offline support
    public func toggleToast(for tastingId: String) async {
        // Find the tasting in the current feed; only tasting entries can be toasted
        guard let currentTasting = entries.lazy.compactMap(\.tasting).first(where: { $0.id == tastingId }) else {
            return
        }
        let newToastedState = !currentTasting.hasToasted
        let isConnected = NetworkMonitor.shared.isConnected
        let offlineOperation: OfflineOperation?

        if isConnected {
            offlineOperation = nil
        } else {
            do {
                offlineOperation = try OfflineOperation.toggleToast(
                    tastingId: tastingId,
                    isToasted: newToastedState
                )
            } catch {
                Telemetry.capture(error, feature: "feed", operation: "queue_toast")
                ToastManager.shared.showError("Failed to prepare offline toast")
                return
            }
        }

        // Optimistic update - immediately update UI and every cached feed
        replaceTasting(with: Self.toasted(currentTasting, hasToasted: newToastedState))

        // Check network status
        if let offlineOperation {
            await OfflineQueueManager.shared.queueOperation(offlineOperation)

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

                // Update UI with the state the server confirmed
                let correctTasting = Self.toasted(currentTasting, hasToasted: actualToastedState)
                await MainActor.run {
                    replaceTasting(with: correctTasting)
                }

            } catch {
                // Check if it's a network error that should be queued
                if isNetworkError(error) {
                    do {
                        let operation = try OfflineOperation.toggleToast(
                            tastingId: tastingId,
                            isToasted: newToastedState
                        )
                        await OfflineQueueManager.shared.queueOperation(operation)
                        ToastManager.shared.showWarning("Toast queued for sync")
                    } catch {
                        Telemetry.capture(error, feature: "feed", operation: "queue_toast")
                        await MainActor.run {
                            replaceTasting(with: currentTasting)
                            ToastManager.shared.showError("Failed to prepare offline toast")
                        }
                    }
                } else {
                    Telemetry.capture(error, feature: "feed", operation: "toggle_toast")
                    // Revert optimistic update on error
                    await MainActor.run {
                        replaceTasting(with: currentTasting)

                        // Don't set general error for toast failures - they're user-specific actions
                        // Show specific error message via ToastManager
                        if let apiError = error as? APIError,
                           case let .requestFailed(message) = apiError,
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

    /// Replaces a tasting in the visible feed and in every cached feed that contains it.
    private func replaceTasting(with tasting: TastingFeedItem) {
        let entryId = ActivityFeedEntry.tasting(tasting).id
        if let index = entries.firstIndex(where: { $0.id == entryId }) {
            entries[index] = .tasting(tasting)
        }
        for feedType in feedCaches.keys {
            if let cacheIndex = feedCaches[feedType]?.entries.firstIndex(where: { $0.id == entryId }) {
                feedCaches[feedType]?.entries[cacheIndex] = .tasting(tasting)
            }
        }
    }

    /// Copies a tasting with the toast state applied and the count adjusted from the original.
    private static func toasted(_ tasting: TastingFeedItem, hasToasted: Bool) -> TastingFeedItem {
        TastingFeedItem(
            id: tasting.id,
            ratingBand: tasting.ratingBand,
            notes: tasting.notes,
            servingStyle: tasting.servingStyle,
            imageUrl: tasting.imageUrl,
            createdAt: tasting.createdAt,
            userId: tasting.userId,
            username: tasting.username,
            userDisplayName: tasting.userDisplayName,
            userAvatarUrl: tasting.userAvatarUrl,
            bottleId: tasting.bottleId,
            bottleName: tasting.bottleName,
            bottleBrandName: tasting.bottleBrandName,
            bottleCategory: tasting.bottleCategory,
            bottleImageUrl: tasting.bottleImageUrl,
            toastCount: hasToasted ? tasting.toastCount + 1 : max(0, tasting.toastCount - 1),
            commentCount: tasting.commentCount,
            hasToasted: hasToasted,
            tags: tasting.tags,
            location: tasting.location,
            friendUsernames: tasting.friendUsernames,
            bottleIdentity: tasting.bottleIdentity
        )
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
