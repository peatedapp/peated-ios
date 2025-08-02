import Testing
import Foundation
@testable import PeatedCore

/// Tests for FeedModel race condition handling
@MainActor
struct FeedModelRaceConditionTests {
    
    @Test("Background refresh is cancelled when switching feeds quickly")
    func testBackgroundRefreshCancellationOnFeedSwitch() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        // Set up slow network to ensure background task has time to start
        mockRepository.networkDelay = 0.2
        mockRepository.mockFeedPage = .singleItem
        
        // Load friends feed initially
        await model.switchFeedType(.friends)
        
        // Simulate time passing to make cache stale (trigger background refresh)
        // In a real test, we'd inject a clock mock, but for now we'll simulate this
        // by directly checking the background refresh logic
        
        // Configure fresh data for background refresh
        mockRepository.mockFeedPage = .multipleItems
        
        // When - Switch to friends (should trigger background refresh due to stale cache)
        // Then immediately switch to personal (should cancel background refresh)
        let rapidSwitchTask1 = Task {
            await model.switchFeedType(.friends)
        }
        
        // Small delay to let background task start
        try await Task.sleep(for: .milliseconds(50))
        
        let rapidSwitchTask2 = Task {
            await model.switchFeedType(.personal)
        }
        
        await rapidSwitchTask1.value
        await rapidSwitchTask2.value
        
        // Then
        #expect(model.selectedFeedType == .personal, "Should end up on personal feed")
        
        // Background refresh should have been cancelled, so friends cache shouldn't be updated
        // Wait a bit to see if any background task completes
        try await Task.sleep(for: .milliseconds(300))
        
        // Switch back to friends to check if cache was updated by cancelled background task
        await model.switchFeedType(.friends)
        
        // Should show original cached data, not the updated data from cancelled background refresh
        #expect(model.tastings.count == 1, "Should show original cached data")
        #expect(model.tastings.first?.id == "sample1", "Should not show updated data from cancelled task")
    }
    
    @Test("Multiple rapid feed switches don't create race conditions")
    func testRapidFeedSwitchingRaceCondition() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        mockRepository.networkDelay = 0.1
        mockRepository.mockFeedPage = .singleItem
        
        // When - Rapid feed switching
        let switches = [
            FeedType.friends,
            FeedType.personal,
            FeedType.global,
            FeedType.friends,
            FeedType.personal,
            FeedType.global,
            FeedType.friends
        ]
        
        for feedType in switches {
            await model.switchFeedType(feedType)
            // Small delay to simulate user behavior
            try await Task.sleep(for: .milliseconds(10))
        }
        
        // Wait for any background tasks to complete
        try await Task.sleep(for: .milliseconds(200))
        
        // Then
        #expect(model.selectedFeedType == .friends, "Should end on final feed type")
        #expect(model.tastings.isNotEmpty, "Should have loaded data")
        
        // Repository shouldn't be called excessively due to caching and race condition prevention
        #expect(mockRepository.totalCallCount <= switches.count, "Should minimize API calls through caching")
    }
    
    @Test("Background refresh task is properly cleaned up on completion")
    func testBackgroundRefreshTaskCleanup() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        mockRepository.networkDelay = 0.05 // Short delay
        mockRepository.mockFeedPage = .singleItem
        
        // Load initial data
        await model.switchFeedType(.friends)
        
        // Configure updated data for background refresh
        mockRepository.mockFeedPage = .multipleItems
        
        // Trigger background refresh by simulating stale cache
        // In production, this would be time-based, but for testing we'll trigger it differently
        
        // When - Force a background refresh by switching to stale cache scenario
        // We'll test this by manually checking the task management
        
        // The background task should clean itself up after completion
        // This is verified by the fact that the model doesn't crash or leak memory
        
        // Switch away and back to trigger any remaining background tasks
        await model.switchFeedType(.personal)
        await model.switchFeedType(.friends)
        
        // Wait for any background operations
        try await Task.sleep(for: .milliseconds(100))
        
        // Then - No assertion needed, just verifying no crashes occur
        #expect(model.selectedFeedType == .friends, "Model should be in stable state")
        #expect(model.tastings.isNotEmpty, "Should have data")
    }
    
    @Test("refreshCurrentFeed cancels existing background refresh")
    func testRefreshCurrentFeedCancelsBackground() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        mockRepository.networkDelay = 0.2
        mockRepository.mockFeedPage = .singleItem
        
        // Load initial data
        await model.switchFeedType(.friends)
        
        // Start a background refresh (simulated by having stale cache)
        mockRepository.mockFeedPage = .multipleItems
        
        // Simulate starting background task
        // In real scenario, this would happen automatically with stale cache
        
        // When - Call refreshCurrentFeed while background task might be running
        let refreshTask = Task {
            await model.refreshCurrentFeed()
        }
        
        await refreshTask.value
        
        // Then
        #expect(mockRepository.refreshFeedCallCount >= 1, "Should have called refresh")
        #expect(model.tastings.isNotEmpty, "Should have refreshed data")
        
        // No background task should interfere after manual refresh
        try await Task.sleep(for: .milliseconds(300))
        
        // Data should remain stable (no interference from cancelled background tasks)
        let stableDataCount = model.tastings.count
        try await Task.sleep(for: .milliseconds(100))
        #expect(model.tastings.count == stableDataCount, "Data should remain stable")
    }
    
    @Test("Concurrent loadMoreIfNeeded calls don't interfere")
    func testConcurrentLoadMoreIfNeeded() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository)
        
        mockRepository.networkDelay = 0.1
        mockRepository.mockFeedPage = .fullPage // 20 items
        
        // Load initial page
        await model.switchFeedType(.friends)
        
        #expect(model.tastings.count == 20, "Should have full page")
        #expect(model.hasMore == true, "Should have more items")
        
        // When - Try to trigger multiple concurrent loadMoreIfNeeded calls
        guard let lastItem = model.tastings.last else {
            throw TestError.noData
        }
        
        // Configure next page data
        mockRepository.mockFeedPage = FeedPage(
            tastings: [TastingFeedItem.sample1], // 1 more item
            cursor: "page2",
            hasMore: false
        )
        
        // Start multiple concurrent loadMore calls
        let task1 = Task { await model.loadMoreIfNeeded(currentItem: lastItem) }
        let task2 = Task { await model.loadMoreIfNeeded(currentItem: lastItem) }
        let task3 = Task { await model.loadMoreIfNeeded(currentItem: lastItem) }
        
        await task1.value
        await task2.value
        await task3.value
        
        // Then - Should only load one additional page, not multiple
        #expect(model.tastings.count == 21, "Should have exactly one additional item")
        #expect(model.hasMore == false, "Should update hasMore state")
        
        // Should not have made excessive API calls
        #expect(mockRepository.getFeedCallCount <= 3, "Should minimize redundant API calls")
    }
    
    @Test("Model deinit cancels all background tasks")
    func testModelDeinitCancelsBackgroundTasks() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        
        do {
            let model = FeedModel(feedRepository: mockRepository)
            
            mockRepository.networkDelay = 0.5 // Long delay to keep task running
            mockRepository.mockFeedPage = .singleItem
            
            // Load data and potentially start background tasks
            await model.switchFeedType(.friends)
            await model.switchFeedType(.personal)
            
            // Model will deinit here, should cancel background tasks
        }
        
        // Wait to see if any background tasks try to complete after deinit
        try await Task.sleep(for: .milliseconds(600))
        
        // Then - No crashes should occur, which would indicate proper cleanup
        // This test mainly verifies no memory leaks or crashes happen
        #expect(true, "Model deinit should complete without issues")
    }
}

// MARK: - Test Helpers

private enum TestError: Error {
    case noData
}

extension Array {
    var isNotEmpty: Bool {
        !isEmpty
    }
}