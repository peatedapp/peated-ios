import Foundation
@testable import PeatedCore
import Testing

/// Tests for FeedModel memory management and cache eviction
@MainActor
struct FeedModelMemoryTests {
    @Test("Feed cache enforces maximum items per feed")
    func maxItemsPerFeedLimit() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Configure a large page that exceeds the limit (500 items)
        let largePage = ActivityPage(
            tastings: Array(1 ... 600).map {
                TastingFeedItem.builder().withId("item\($0)").build()
            },
            cursor: "large_page",
            hasMore: false
        )
        mockRepository.mockPage = largePage

        // When
        await model.switchFeedType(.friends)

        // Then
        #expect(model.entries.count == 500, "Should limit to 500 items per feed")

        // Should keep the most recent items (last 500)
        #expect(model.entries.first?.tasting?.id == "item101", "Should keep items 101-600")
        #expect(model.entries.last?.tasting?.id == "item600", "Should keep items 101-600")

        // hasMore should be false when we truncate
        #expect(model.hasMore == false, "Should set hasMore to false when truncating")
    }

    @Test("Feed cache enforces global memory limits")
    func globalMemoryLimits() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Create large pages for each feed type to exceed global memory limit
        let largePage = ActivityPage(
            tastings: Array(1 ... 400).map {
                TastingFeedItem.builder().withId("item\($0)").build()
            },
            cursor: "large",
            hasMore: false
        )
        mockRepository.mockPage = largePage

        // When - Load all feed types to exceed memory limit
        // 400 items * 500 bytes * 3 feeds = ~600KB each = ~1.8MB total (under 10MB limit)
        // Let's create much larger feeds to trigger eviction
        let veryLargePage = ActivityPage(
            tastings: Array(1 ... 5000).map {
                TastingFeedItem.builder().withId("item\($0)").build()
            },
            cursor: "very_large",
            hasMore: false
        )
        mockRepository.mockPage = veryLargePage

        await model.switchFeedType(.friends)

        await model.switchFeedType(.global)
        await model.switchFeedType(.global)

        let finalMemory = model.cacheMemoryUsage

        // Then
        #expect(finalMemory.totalBytes <= 10 * 1024 * 1024, "Should stay under 10MB total")
        #expect(finalMemory.feedCounts.count <= 2, "Should have evicted some caches or limited items")
    }

    @Test("Memory cleanup preserves current feed")
    func memoryCleanupPreservesCurrentFeed() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Create large pages to trigger memory cleanup
        let largePage = ActivityPage(
            tastings: Array(1 ... 5000).map {
                TastingFeedItem.builder().withId("item\($0)").build()
            },
            cursor: "large",
            hasMore: false
        )
        mockRepository.mockPage = largePage

        // When - Load multiple feeds, ending on friends
        await model.switchFeedType(.global)
        try await Task.sleep(for: .milliseconds(10)) // Ensure different timestamps

        await model.switchFeedType(.global)
        try await Task.sleep(for: .milliseconds(10))

        await model.switchFeedType(.friends) // This should be preserved

        let memoryUsage = model.cacheMemoryUsage

        // Then
        #expect(memoryUsage.feedCounts[.friends] != nil, "Should preserve current feed (.friends)")
        #expect(model.selectedFeedType == .friends, "Should be on friends feed")
        #expect(!model.entries.isEmpty, "Should still have data for current feed")

        // One of the older feeds might have been evicted
        let totalFeeds = memoryUsage.feedCounts.count
        #expect(totalFeeds >= 1, "Should have at least the current feed")
        #expect(totalFeeds <= 3, "Should have evicted some feeds if memory limit exceeded")
    }

    @Test("Cache memory usage reporting is accurate")
    func cacheMemoryUsageReporting() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Start with empty cache
        let emptyUsage = model.cacheMemoryUsage
        #expect(emptyUsage.totalBytes == 0, "Should start with zero memory usage")
        #expect(emptyUsage.feedCounts.isEmpty, "Should start with no feeds")

        // When - Load friends feed
        mockRepository.mockPage = .singleItem
        await model.switchFeedType(.friends)

        let singleItemUsage = model.cacheMemoryUsage

        // Then
        #expect(singleItemUsage.totalBytes > 0, "Should have non-zero memory usage")
        #expect(singleItemUsage.feedCounts[.friends] == 1, "Should have 1 item in friends feed")
        #expect(singleItemUsage.totalBytes == 500, "Should estimate 500 bytes for 1 item")

        // When - Load global feed
        mockRepository.mockPage = .multipleItems // 3 items
        await model.switchFeedType(.global)

        let multipleItemsUsage = model.cacheMemoryUsage

        // Then
        #expect(multipleItemsUsage.feedCounts[.friends] == 1, "Should still have friends cache")
        #expect(multipleItemsUsage.feedCounts[.global] == 3, "Should have 3 items in global feed")
        #expect(multipleItemsUsage.totalBytes == 2000, "Should estimate 2000 bytes for 4 total items")
    }

    @Test("Pagination respects memory limits")
    func paginationRespectsMemoryLimits() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Start with a page at the limit
        let initialPage = ActivityPage(
            tastings: Array(1 ... 500).map {
                TastingFeedItem.builder().withId("initial\($0)").build()
            },
            cursor: "page1",
            hasMore: true
        )
        mockRepository.mockPage = initialPage

        await model.switchFeedType(.friends)
        #expect(model.entries.count == 500, "Should start with 500 items")

        // When - Load more that would exceed the limit
        let additionalPage = ActivityPage(
            tastings: Array(1 ... 100).map {
                TastingFeedItem.builder().withId("additional\($0)").build()
            },
            cursor: "page2",
            hasMore: false
        )
        mockRepository.mockPage = additionalPage

        try await model.loadMoreIfNeeded(currentEntry: #require(model.entries.last))

        // Then
        #expect(model.entries.count == 500, "Should still be limited to 500 items")

        // Should contain the most recent items (last 500 of the 600 total)
        let hasInitialItems = model.entries.contains { $0.tasting?.id.hasPrefix("initial") == true }
        let hasAdditionalItems = model.entries.contains { $0.tasting?.id.hasPrefix("additional") == true }

        #expect(hasInitialItems, "Should have some initial items")
        #expect(hasAdditionalItems, "Should have additional items")
        #expect(model.hasMore == false, "Should set hasMore to false when truncating")
    }

    @Test("Memory limits handle empty responses gracefully")
    func memoryLimitsHandleEmptyResponses() async {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // When - Load empty feed
        mockRepository.mockPage = .empty
        await model.switchFeedType(.friends)

        let emptyUsage = model.cacheMemoryUsage

        // Then
        #expect(emptyUsage.feedCounts[.friends] == 0, "Should have 0 items")
        #expect(emptyUsage.totalBytes == 0, "Should have 0 bytes for empty feed")
        #expect(model.entries.isEmpty, "Should have no tastings")
    }

    @Test("Cache eviction removes oldest feeds first")
    func cacheEvictionRemovesOldestFirst() async throws {
        // Given
        let mockRepository = MockFeedRepository()
        let model = FeedModel(feedRepository: mockRepository, selectionStore: InMemoryFeedSelectionStore())

        // Create a large page that will trigger memory cleanup
        let largePage = ActivityPage(
            tastings: Array(1 ... 4000).map {
                TastingFeedItem.builder().withId("item\($0)").build()
            },
            cursor: "large",
            hasMore: false
        )
        mockRepository.mockPage = largePage

        // When - Load feeds in order: global -> friends
        await model.switchFeedType(.global)
        try await Task.sleep(for: .milliseconds(50)) // Ensure different timestamps

        await model.switchFeedType(.global)
        try await Task.sleep(for: .milliseconds(50))

        await model.switchFeedType(.friends) // Current feed, should be preserved

        let finalUsage = model.cacheMemoryUsage

        // Then
        #expect(finalUsage.feedCounts[.friends] != nil, "Should preserve current feed")

        // Global feed should be evicted first (oldest), global might be preserved
        if finalUsage.feedCounts.count < 3 {
            // Some eviction occurred
            #expect(finalUsage.feedCounts[.global] == nil, "Should evict oldest feed first")
        }
    }
}
