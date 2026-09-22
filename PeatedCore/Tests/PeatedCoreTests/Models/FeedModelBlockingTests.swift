import Foundation
@testable import PeatedCore
import Testing

/// A block must hide a member's cached entries before the feed is fetched again.
@MainActor
struct FeedModelBlockingTests {
    @Test
    func blockedMemberDisappearsFromCachedFeed() async {
        let repository = MockFeedRepository()
        let blockList = BlockList(store: InMemoryBlockListStore())
        let model = FeedModel(
            feedRepository: repository,
            selectionStore: InMemoryFeedSelectionStore(),
            blockList: blockList
        )
        repository.mockPage = ActivityPage(
            tastings: [
                TastingFeedItem.builder().withId("t1").withUserId("alice").build(),
                TastingFeedItem.builder().withId("t2").withUserId("bob").build(),
                TastingFeedItem.builder().withId("t3").withUserId("alice").build()
            ],
            cursor: nil,
            hasMore: false
        )
        await model.switchFeedType(.friends)
        #expect(model.entries.count == 3)

        blockList.add("alice")

        #expect(model.entries.map(\.tasting?.id) == ["t2"])
        #expect(repository.totalCallCount == 1, "Filtering must not refetch")

        // The cached copy stays filtered after switching away and back.
        await model.switchFeedType(.global)
        await model.switchFeedType(.friends)
        #expect(model.entries.map(\.tasting?.id) == ["t2"])
    }

    @Test
    func unblockingRestoresTheMembersEntries() async {
        let repository = MockFeedRepository()
        let blockList = BlockList(store: InMemoryBlockListStore(ids: ["alice"]))
        let model = FeedModel(
            feedRepository: repository,
            selectionStore: InMemoryFeedSelectionStore(),
            blockList: blockList
        )
        repository.mockPage = ActivityPage(
            tastings: [
                TastingFeedItem.builder().withId("t1").withUserId("alice").build(),
                TastingFeedItem.builder().withId("t2").withUserId("bob").build()
            ],
            cursor: nil,
            hasMore: false
        )
        await model.switchFeedType(.friends)
        #expect(model.entries.map(\.tasting?.id) == ["t2"])

        blockList.remove("alice")

        #expect(model.entries.map(\.tasting?.id) == ["t1", "t2"])
    }

    @Test
    func criticReviewsHaveNoMemberToBlock() {
        let review = CriticReviewFeedItem(
            id: "c1",
            url: "https://example.com/review",
            sourceName: "Whisky Weekly",
            sourceImageUrl: nil,
            byline: nil,
            excerpt: nil,
            score: nil,
            tags: [],
            createdAt: Date(),
            bottle: ActivityBottleSummary(
                id: "b1",
                imageUrl: nil,
                identity: BottleIdentity(name: "Test", provenance: [], metadata: [])
            )
        )

        #expect(ActivityFeedEntry.criticReview(review).actorUserId == nil)
    }
}
