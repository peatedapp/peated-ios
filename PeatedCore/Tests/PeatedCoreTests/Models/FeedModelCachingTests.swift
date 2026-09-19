import Foundation
@testable import PeatedCore
import Testing

/// Tests for FeedModel caching behavior
@MainActor
struct FeedModelCachingTests {
    // MARK: - Basic Caching Tests

    @Test("Feed data is cached after initial load")
    func feedDataIsCached() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Configure mock to return sample data
        mockRepository.mockPage = .singleItem

        // When - Load friends feed for the first time
        await model.switchFeedType(.friends)
        let firstCallCount = mockRepository.getFeedCallCount

        // Switch to a different feed type
        await model.switchFeedType(.global)

        // Switch back to friends feed
        await model.switchFeedType(.friends)
        let secondCallCount = mockRepository.getFeedCallCount

        // Then
        #expect(firstCallCount == 1, "Should make initial API call")
        #expect(secondCallCount == 2, "Should only load the uncached global feed")
        #expect(model.entries.count == 1, "Should show cached data")
        #expect(model.entries.first?.tasting?.id == "sample1", "Should show correct cached item")
    }

    @Test("Different feed types have separate caches")
    func separateCachesForDifferentFeedTypes() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Configure different data for different feed types
        mockRepository.mockPage = .singleItem

        // When - Load friends feed
        await model.switchFeedType(.friends)
        let friendsCallCount = mockRepository.getFeedCallCount

        // Configure different data for global feed
        mockRepository.mockPage = .multipleItems
        await model.switchFeedType(.global)
        let globalCallCount = mockRepository.getFeedCallCount

        // Switch back to friends
        await model.switchFeedType(.friends)
        let finalCallCount = mockRepository.getFeedCallCount

        // Then
        #expect(friendsCallCount == 1, "Should load friends feed")
        #expect(globalCallCount == 2, "Should load global feed (separate cache)")
        #expect(finalCallCount == 2, "Should use cached friends data")
        #expect(model.entries.count == 1, "Should show cached friends data")
    }

    // MARK: - Pull to Refresh Tests

    @Test("Pull to refresh clears cache and loads fresh data")
    func pullToRefreshClearsCache() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Initial load with sample1
        mockRepository.mockPage = .singleItem
        await model.switchFeedType(.friends)

        #expect(model.entries.first?.tasting?.id == "sample1", "Initial data should be sample1")

        // When - Simulate updated data from server
        mockRepository.mockPage = ActivityPage(
            tastings: [TastingFeedItem.sample2], // Different data
            cursor: "new_cursor",
            hasMore: false
        )

        // Pull to refresh
        await model.refreshCurrentFeed()

        // Then
        #expect(mockRepository.refreshFeedCallCount == 1, "Should call refresh")
        #expect(model.entries.first?.tasting?.id == "sample2", "Should show updated data")
        #expect(model.hasMore == false, "Should update hasMore state")

        // Verify cache was updated by switching away and back
        await model.switchFeedType(.global)
        await model.switchFeedType(.friends)

        #expect(model.entries.first?.tasting?.id == "sample2", "Cache should contain updated data")
    }

    // MARK: - Error Handling Tests

    @Test("Network error during initial load shows error state")
    func networkErrorDuringInitialLoad() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Configure repository to throw error
        struct TestError: Error {}
        mockRepository.mockError = TestError()

        // When
        await model.switchFeedType(.friends)

        // Then
        #expect(model.error != nil, "Should set error state")
        #expect(model.entries.isEmpty, "Should have no tastings")
        #expect(model.isLoading == false, "Should not be loading")
    }

    // MARK: - Cache State Tests

    @Test("Model shows correct loading states during feed switching")
    func loadingStatesDuringFeedSwitching() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Configure slow network response
        mockRepository.networkDelay = 0.1
        mockRepository.mockPage = .singleItem

        // When - Switch to friends feed (no cache)
        let switchTask = Task {
            await model.switchFeedType(.friends)
        }

        // Allow the child task to begin before checking its observable state.
        await Task.yield()
        #expect(model.isSwitchingFeed == true, "Should show switching feed state")

        await switchTask.value

        // Then - After load completes
        #expect(model.isSwitchingFeed == false, "Should not be switching feed")
        #expect(model.isLoading == false, "Should not be loading")
        #expect(model.entries.count == 1, "Should have loaded data")

        // When - Switch to cached feed (should be instant)
        await model.switchFeedType(.global)
        await model.switchFeedType(.friends) // Back to cached data

        // Then - Should not show loading states for cached data
        #expect(model.isSwitchingFeed == false, "Should not switch for cached data")
        #expect(model.isLoading == false, "Should not load for cached data")
    }

    @Test("Cache preserves pagination state")
    func cachePreservesPaginationState() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Configure initial page
        mockRepository.mockPage = ActivityPage(
            tastings: [TastingFeedItem.sample1],
            cursor: "page1_cursor",
            hasMore: true
        )

        // When - Load initial page
        await model.switchFeedType(.friends)

        // Verify initial state
        #expect(model.entries.count == 1, "Should have initial items")
        #expect(model.hasMore == true, "Should have more items")

        // Switch away and back
        await model.switchFeedType(.global)
        await model.switchFeedType(.friends)

        // Then - Pagination state should be preserved
        #expect(model.entries.count == 1, "Should preserve tasting count")
        #expect(model.hasMore == true, "Should preserve hasMore state")
    }

    // MARK: - Performance Tests

    @Test("Cache access is significantly faster than network")
    func cachePerformance() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Configure repository with network delay
        mockRepository.networkDelay = 0.2 // 200ms delay
        mockRepository.mockPage = .singleItem

        // When - First load (network)
        let networkStartTime = Date()
        await model.switchFeedType(.friends)
        let networkDuration = Date().timeIntervalSince(networkStartTime)

        // Switch away
        await model.switchFeedType(.global)

        // Switch back (cache)
        let cacheStartTime = Date()
        await model.switchFeedType(.friends)
        let cacheDuration = Date().timeIntervalSince(cacheStartTime)

        // Then
        #expect(networkDuration > 0.15, "Network call should take significant time")
        #expect(cacheDuration < 0.05, "Cache access should be fast (under 50ms)")
        #expect(cacheDuration < networkDuration / 2, "Cache should be at least 2x faster")
    }

    // MARK: - Cache Invalidation Tests

    @Test("refreshCurrentFeed clears cache for current feed type only")
    func refreshCurrentFeedClearsOnlyCurrentCache() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Load friends feed
        mockRepository.mockPage = .singleItem
        await model.switchFeedType(.friends)

        // Load global feed
        mockRepository.mockPage = .multipleItems
        await model.switchFeedType(.global)

        // Switch back to friends
        await model.switchFeedType(.friends)
        let callCountBeforeRefresh = mockRepository.totalCallCount

        // When - Refresh current feed (friends)
        mockRepository.mockPage = ActivityPage(
            tastings: [TastingFeedItem.sample3],
            cursor: nil,
            hasMore: false
        )
        await model.refreshCurrentFeed()

        // Then - Friends cache should be cleared and reloaded
        #expect(model.entries.first?.tasting?.id == "sample3", "Should show refreshed data")

        // Switch to global feed - should still use cache
        await model.switchFeedType(.global)
        let finalCallCount = mockRepository.totalCallCount

        #expect(model.entries.count == 3, "Global feed should still be cached")
        #expect(finalCallCount == callCountBeforeRefresh + 1, "Should only refresh friends, not global")
    }

    // MARK: - Edge Cases

    @Test("Empty feed response is cached correctly")
    func emptyFeedCaching() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Configure empty response
        mockRepository.mockPage = .empty

        // When
        await model.switchFeedType(.friends)
        let firstCallCount = mockRepository.getFeedCallCount

        // Switch away and back
        await model.switchFeedType(.global)
        await model.switchFeedType(.friends)
        let secondCallCount = mockRepository.getFeedCallCount

        // Then
        #expect(firstCallCount == 1, "Should make initial call")
        #expect(secondCallCount == 2, "Should only load the uncached global feed")
        #expect(model.entries.isEmpty, "Should show empty cached result")
        #expect(model.hasMore == false, "Should cache hasMore state")
    }

    @Test("Rapid feed switching uses cache efficiently")
    func rapidFeedSwitching() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        mockRepository.mockPage = .singleItem

        // When - Load friends feed first
        await model.switchFeedType(.friends)

        // Rapid switching
        await model.switchFeedType(.global)
        await model.switchFeedType(.global)
        await model.switchFeedType(.friends) // Back to cached
        await model.switchFeedType(.global) // New load
        await model.switchFeedType(.friends) // Cached again

        // Then
        #expect(mockRepository.getFeedCallCount <= 3, "Should minimize API calls through caching")
        #expect(model.entries.count == 1, "Should show correct final data")
    }
}
