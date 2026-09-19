import Foundation
import PeatedAPI

/// Feed rows mapped from one API activity result, plus the bottles those rows
/// mention so the repository can seed the bottle cache without a second pass.
struct ActivityFeedMapping {
    var entries: [ActivityFeedEntry] = []
    var bottles: [Bottle] = []
}

/// The member-review payload fields the feed needs.
private struct MemberReviewFields {
    let id: Int
    let score: Int
    let notes: String?
    let imageUrl: String?
    let tags: [String]
    let bottle: Components.Schemas.Bottle
}

/// The collection-add payload fields the feed needs.
private struct CollectionAddFields {
    let name: String
    let href: String?
    let totalBottles: Int
    let items: [Components.Schemas.CollectionBottle]
}

extension ActivityFeedMapping {
    init(_ result: Operations.listActivity.Output.Ok.Body.jsonPayload.resultsPayloadPayload) {
        self.init()
        if let session = result.value1 {
            addTastings(session.tastings)
        } else if let add = result.value2 {
            addCollectionAdd(
                entryId: add.id,
                createdAt: add.createdAt,
                createdBy: add.createdBy,
                collection: CollectionAddFields(
                    name: add.collection.name,
                    href: add.collection.href,
                    totalBottles: add.totalItems,
                    items: add.items
                )
            )
        } else if let entry = result.value3 {
            addMemberReview(
                createdAt: entry.createdAt,
                createdBy: entry.createdBy,
                review: MemberReviewFields(
                    id: entry.review.id,
                    score: entry.review.score,
                    notes: entry.review.notes,
                    imageUrl: entry.review.imageUrl,
                    tags: entry.review.tags ?? [],
                    bottle: entry.review.bottle
                )
            )
        } else if let entry = result.value4 {
            addCriticReview(createdAt: entry.createdAt, review: entry.review)
        }
    }

    // MARK: - Shared builders

    /// A session is one member's tastings close together; the feed shows each tasting.
    private mutating func addTastings(_ tastings: [Components.Schemas.Tasting]) {
        for tasting in tastings {
            entries.append(.tasting(TastingFeedItem.from(tasting)))
            bottles.append(Bottle(from: tasting.bottle))
        }
    }

    private mutating func addMemberReview(
        createdAt: Date,
        createdBy: Components.Schemas.User,
        review: MemberReviewFields
    ) {
        let bottle = Bottle(from: review.bottle)
        bottles.append(bottle)
        entries.append(.memberReview(MemberReviewFeedItem(
            id: String(review.id),
            score: review.score,
            notes: review.notes,
            imageUrl: review.imageUrl,
            tags: review.tags,
            createdAt: createdAt,
            userId: String(Int(createdBy.id)),
            username: createdBy.username,
            userAvatarUrl: createdBy.pictureUrl,
            bottle: ActivityBottleSummary(bottle)
        )))
    }

    /// Reviews without a resolved bottle have nothing to show and are skipped, as on the web.
    private mutating func addCriticReview(createdAt: Date, review: Components.Schemas.ExternalReview) {
        guard let apiBottle = review.bottle else { return }
        let bottle = Bottle(from: apiBottle)
        bottles.append(bottle)
        let sourceName = review.site?.name ?? review.reviewerName ?? "Critic"
        let byline = review.reviewerName.flatMap { $0 == sourceName ? nil : $0 }
        entries.append(.criticReview(CriticReviewFeedItem(
            id: String(Int(review.id)),
            url: review.url,
            sourceName: sourceName,
            sourceImageUrl: review.site?.imageUrl,
            byline: byline,
            excerpt: review.clip ?? review.article.title,
            score: review.nativeScore.map {
                CriticReviewFeedItem.Score(value: $0.value, scale: $0.scale, display: $0.display)
            },
            tags: review.extractedTags,
            createdAt: createdAt,
            bottle: ActivityBottleSummary(bottle)
        )))
    }

    /// Favorites are not feed events, matching the web profile rule.
    private mutating func addCollectionAdd(
        entryId: String,
        createdAt: Date,
        createdBy: Components.Schemas.User,
        collection: CollectionAddFields
    ) {
        if collection.href?.hasSuffix("/favorites") == true {
            return
        }
        let itemBottles = collection.items.map { Bottle(from: $0.bottle, imageUrl: $0.imageUrl) }
        bottles.append(contentsOf: itemBottles)
        entries.append(.collectionAdd(CollectionAddFeedItem(
            id: entryId,
            createdAt: createdAt,
            userId: String(Int(createdBy.id)),
            username: createdBy.username,
            userAvatarUrl: createdBy.pictureUrl,
            isLibrary: collection.href?.hasSuffix("/library") == true,
            collectionName: collection.name,
            totalBottles: collection.totalBottles,
            bottles: itemBottles.map { ActivityBottleSummary($0) }
        )))
    }
}
