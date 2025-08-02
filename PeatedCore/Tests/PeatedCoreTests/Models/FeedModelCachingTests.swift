import Testing
import Foundation
@testable import PeatedCore

/// Tests for FeedModel caching behavior
@MainActor
struct FeedModelCachingTests {
    
    // MARK: - Basic Caching Tests
    
    @Test("Feed data is cached after initial load")
    func testFeedDataIsCached() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        // Configure mock to return sample data
        mockRepository.mockFeedPage = .singleItem
        
        // When - Load friends feed for the first time
        await model.switchFeedType(.friends)
        let firstCallCount = mockRepository.getFeedCallCount
        
        // Switch to a different feed type
        await model.switchFeedType(.personal)
        
        // Switch back to friends feed
        await model.switchFeedType(.friends)
        let secondCallCount = mockRepository.getFeedCallCount
        
        // Then
        #expect(firstCallCount == 1, "Should make initial API call")
        #expect(secondCallCount == 1, "Should not make additional API call due to caching")
        #expect(model.tastings.count == 1, "Should show cached data")
        #expect(model.tastings.first?.id == "sample1", "Should show correct cached item")
    }
    
    @Test("Different feed types have separate caches")
    func testSeparateCachesForDifferentFeedTypes() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        // Configure different data for different feed types
        mockRepository.mockFeedPage = .singleItem
        
        // When - Load friends feed
        await model.switchFeedType(.friends)
        let friendsCallCount = mockRepository.getFeedCallCount
        
        // Configure different data for personal feed
        mockRepository.mockFeedPage = .multipleItems
        await model.switchFeedType(.personal)
        let personalCallCount = mockRepository.getFeedCallCount
        
        // Switch back to friends
        await model.switchFeedType(.friends)
        let finalCallCount = mockRepository.getFeedCallCount
        
        // Then
        #expect(friendsCallCount == 1, "Should load friends feed")
        #expect(personalCallCount == 2, "Should load personal feed (separate cache)")
        #expect(finalCallCount == 2, "Should use cached friends data")
        #expect(model.tastings.count == 1, "Should show cached friends data")
    }
    
    // MARK: - Pull to Refresh Tests
    
    @Test("Pull to refresh clears cache and loads fresh data")
    func testPullToRefreshClearsCache() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        // Initial load with sample1
        mockRepository.mockFeedPage = .singleItem
        await model.switchFeedType(.friends)
        
        #expect(model.tastings.first?.id == "sample1", "Initial data should be sample1")
        
        // When - Simulate updated data from server
        mockRepository.mockFeedPage = FeedPage(
            tastings: [TastingFeedItem.sample2], // Different data
            cursor: "new_cursor",
            hasMore: false
        )
        
        // Pull to refresh
        await model.refreshCurrentFeed()
        
        // Then
        #expect(mockRepository.refreshFeedCallCount == 1, "Should call refresh")
        #expect(model.tastings.first?.id == "sample2", "Should show updated data")
        #expect(model.hasMore == false, "Should update hasMore state")
        
        // Verify cache was updated by switching away and back
        await model.switchFeedType(.personal)
        await model.switchFeedType(.friends)
        
        #expect(model.tastings.first?.id == "sample2", "Cache should contain updated data")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Network error during initial load shows error state")
    func testNetworkErrorDuringInitialLoad() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        // Configure repository to throw error
        struct TestError: Error {}
        mockRepository.mockError = TestError()
        
        // When
        await model.switchFeedType(.friends)
        
        // Then
        #expect(model.error != nil, "Should set error state")
        #expect(model.tastings.isEmpty, "Should have no tastings")
        #expect(model.isLoading == false, "Should not be loading")
    }
    
    // MARK: - Cache State Tests
    
    @Test("Model shows correct loading states during feed switching")
    func testLoadingStatesDuringFeedSwitching() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        // Configure slow network response
        mockRepository.networkDelay = 0.1
        mockRepository.mockFeedPage = .singleItem
        
        // When - Switch to friends feed (no cache)
        let switchTask = Task {
            await model.switchFeedType(.friends)
        }
        
        // Check loading state immediately
        #expect(model.isSwitchingFeed == true, "Should show switching feed state")
        
        await switchTask.value
        
        // Then - After load completes
        #expect(model.isSwitchingFeed == false, "Should not be switching feed")
        #expect(model.isLoading == false, "Should not be loading")
        #expect(model.tastings.count == 1, "Should have loaded data")
        
        // When - Switch to cached feed (should be instant)
        await model.switchFeedType(.personal)
        await model.switchFeedType(.friends) // Back to cached data
        
        // Then - Should not show loading states for cached data
        #expect(model.isSwitchingFeed == false, "Should not switch for cached data")
        #expect(model.isLoading == false, "Should not load for cached data")
    }
    
    @Test("Cache preserves pagination state")
    func testCachePreservesPaginationState() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        // Configure initial page
        mockRepository.mockFeedPage = FeedPage(
            tastings: [TastingFeedItem.sample1],
            cursor: "page1_cursor",
            hasMore: true
        )
        
        // When - Load initial page
        await model.switchFeedType(.friends)
        
        // Verify initial state
        #expect(model.tastings.count == 1, "Should have initial items")
        #expect(model.hasMore == true, "Should have more items")
        
        // Switch away and back
        await model.switchFeedType(.personal)
        await model.switchFeedType(.friends)
        
        // Then - Pagination state should be preserved
        #expect(model.tastings.count == 1, "Should preserve tasting count")
        #expect(model.hasMore == true, "Should preserve hasMore state")
    }
    
    // MARK: - Performance Tests
    
    @Test("Cache access is significantly faster than network")
    func testCachePerformance() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        // Configure repository with network delay
        mockRepository.networkDelay = 0.2 // 200ms delay
        mockRepository.mockFeedPage = .singleItem
        
        // When - First load (network)
        let networkStartTime = Date()
        await model.switchFeedType(.friends)
        let networkDuration = Date().timeIntervalSince(networkStartTime)
        
        // Switch away
        await model.switchFeedType(.personal)
        
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
    func testRefreshCurrentFeedClearsOnlyCurrentCache() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        // Load friends feed
        mockRepository.mockFeedPage = .singleItem
        await model.switchFeedType(.friends)
        
        // Load personal feed
        mockRepository.mockFeedPage = .multipleItems
        await model.switchFeedType(.personal)
        
        // Switch back to friends
        await model.switchFeedType(.friends)
        let callCountBeforeRefresh = mockRepository.totalCallCount
        
        // When - Refresh current feed (friends)
        mockRepository.mockFeedPage = FeedPage(
            tastings: [TastingFeedItem.sample3],
            cursor: nil,
            hasMore: false
        )
        await model.refreshCurrentFeed()
        
        // Then - Friends cache should be cleared and reloaded
        #expect(model.tastings.first?.id == "sample3", "Should show refreshed data")
        
        // Switch to personal feed - should still use cache
        await model.switchFeedType(.personal)
        let finalCallCount = mockRepository.totalCallCount
        
        #expect(model.tastings.count == 3, "Personal feed should still be cached")
        #expect(finalCallCount == callCountBeforeRefresh + 1, "Should only refresh friends, not personal")
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty feed response is cached correctly")
    func testEmptyFeedCaching() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        // Configure empty response
        mockRepository.mockFeedPage = .empty
        
        // When
        await model.switchFeedType(.friends)
        let firstCallCount = mockRepository.getFeedCallCount
        
        // Switch away and back
        await model.switchFeedType(.personal)
        await model.switchFeedType(.friends)
        let secondCallCount = mockRepository.getFeedCallCount
        
        // Then
        #expect(firstCallCount == 1, "Should make initial call")
        #expect(secondCallCount == 1, "Should not make second call (cached)")
        #expect(model.tastings.isEmpty, "Should show empty cached result")
        #expect(model.hasMore == false, "Should cache hasMore state")
    }
    
    @Test("Rapid feed switching uses cache efficiently")
    func testRapidFeedSwitching() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        mockRepository.mockFeedPage = .singleItem
        
        // When - Load friends feed first
        await model.switchFeedType(.friends)
        
        // Rapid switching
        await model.switchFeedType(.personal)
        await model.switchFeedType(.global)
        await model.switchFeedType(.friends) // Back to cached
        await model.switchFeedType(.personal) // New load
        await model.switchFeedType(.friends) // Cached again
        
        // Then
        #expect(mockRepository.getFeedCallCount <= 3, "Should minimize API calls through caching")
        #expect(model.tastings.count == 1, "Should show correct final data")
    }
}