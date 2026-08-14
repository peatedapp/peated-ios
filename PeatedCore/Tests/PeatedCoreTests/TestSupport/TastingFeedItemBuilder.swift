import Foundation
@testable import PeatedCore

/// Builder pattern for creating TastingFeedItem test data
public class TastingFeedItemBuilder {
    private var id = "1"
    private var rating = 4.0
    private var notes: String?
    private var servingStyle: String? = "neat"
    private var imageUrl: String?
    private var createdAt = Date()
    private var userId = "user1"
    private var username = "testuser"
    private var userDisplayName: String?
    private var userAvatarUrl: String?
    private var bottleId = "bottle1"
    private var bottleName = "Test Whisky"
    private var bottleBrandName = "Test Distillery"
    private var bottleCategory: String? = "scotch"
    private var bottleImageUrl: String?
    private var toastCount = 0
    private var commentCount = 0
    private var hasToasted = false
    private var tags: [String] = []
    private var location: String?
    private var friendUsernames: [String] = []

    public init() {}

    public func withId(_ id: String) -> TastingFeedItemBuilder {
        self.id = id
        return self
    }

    public func withRating(_ rating: Double) -> TastingFeedItemBuilder {
        self.rating = rating
        return self
    }

    public func withNotes(_ notes: String?) -> TastingFeedItemBuilder {
        self.notes = notes
        return self
    }

    public func withBottleName(_ name: String) -> TastingFeedItemBuilder {
        bottleName = name
        return self
    }

    public func withBrandName(_ brandName: String) -> TastingFeedItemBuilder {
        bottleBrandName = brandName
        return self
    }

    public func withUsername(_ username: String) -> TastingFeedItemBuilder {
        self.username = username
        return self
    }

    public func withCreatedAt(_ date: Date) -> TastingFeedItemBuilder {
        createdAt = date
        return self
    }

    public func withToastCount(_ count: Int) -> TastingFeedItemBuilder {
        toastCount = count
        return self
    }

    public func withCommentCount(_ count: Int) -> TastingFeedItemBuilder {
        commentCount = count
        return self
    }

    public func withTags(_ tags: [String]) -> TastingFeedItemBuilder {
        self.tags = tags
        return self
    }

    public func hasToasted(_ toasted: Bool = true) -> TastingFeedItemBuilder {
        hasToasted = toasted
        return self
    }

    public func build() -> TastingFeedItem {
        TastingFeedItem(
            id: id,
            rating: rating,
            notes: notes,
            servingStyle: servingStyle,
            imageUrl: imageUrl,
            createdAt: createdAt,
            userId: userId,
            username: username,
            userDisplayName: userDisplayName,
            userAvatarUrl: userAvatarUrl,
            bottleId: bottleId,
            bottleName: bottleName,
            bottleBrandName: bottleBrandName,
            bottleCategory: bottleCategory,
            bottleImageUrl: bottleImageUrl,
            toastCount: toastCount,
            commentCount: commentCount,
            hasToasted: hasToasted,
            tags: tags,
            location: location,
            friendUsernames: friendUsernames
        )
    }
}

// MARK: - Convenience Extensions

public extension TastingFeedItem {
    /// Create a new builder instance
    static func builder() -> TastingFeedItemBuilder {
        TastingFeedItemBuilder()
    }

    /// Sample tasting for tests
    static var sample1: TastingFeedItem {
        builder()
            .withId("sample1")
            .withBottleName("Lagavulin 16-year-old")
            .withBrandName("Lagavulin")
            .withUsername("whisky_lover")
            .withRating(4.5)
            .withNotes("Smoky and peaty with hints of seaweed")
            .withToastCount(12)
            .withCommentCount(3)
            .withTags(["peaty", "smoky", "islay"])
            .build()
    }

    /// Another sample for variety
    static var sample2: TastingFeedItem {
        builder()
            .withId("sample2")
            .withBottleName("Glenfiddich 12-year-old")
            .withBrandName("Glenfiddich")
            .withUsername("highland_fan")
            .withRating(3.8)
            .withNotes("Light and fruity with apple notes")
            .withToastCount(8)
            .withCommentCount(1)
            .withTags(["fruity", "light", "speyside"])
            .build()
    }

    /// Sample for a different user
    static var sample3: TastingFeedItem {
        builder()
            .withId("sample3")
            .withBottleName("Macallan 18-year-old")
            .withBrandName("Macallan")
            .withUsername("sherry_cask_lover")
            .withRating(4.8)
            .withNotes("Rich sherry influence with dried fruits")
            .withToastCount(25)
            .withCommentCount(7)
            .hasToasted()
            .withTags(["sherry", "rich", "highland"])
            .build()
    }
}

// MARK: - FeedPage Test Helpers

public extension FeedPage {
    /// Empty feed page for tests
    static var empty: FeedPage {
        FeedPage(tastings: [], cursor: nil, hasMore: false)
    }

    /// Single item feed page
    static var singleItem: FeedPage {
        FeedPage(
            tastings: [TastingFeedItem.sample1],
            cursor: "123",
            hasMore: true
        )
    }

    /// Multiple items feed page
    static var multipleItems: FeedPage {
        FeedPage(
            tastings: [
                TastingFeedItem.sample1,
                TastingFeedItem.sample2,
                TastingFeedItem.sample3
            ],
            cursor: "456",
            hasMore: true
        )
    }

    /// Full page (20 items) for pagination testing
    static var fullPage: FeedPage {
        let tastings = (1 ... 20).map { index in
            TastingFeedItem.builder()
                .withId("item\(index)")
                .withBottleName("Test Bottle \(index)")
                .withUsername("user\(index)")
                .withRating(Double.random(in: 3.0 ... 5.0))
                .build()
        }
        return FeedPage(tastings: tastings, cursor: "999", hasMore: true)
    }
}
