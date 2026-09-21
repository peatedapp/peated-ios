import Foundation
@testable import PeatedAPI
@testable import PeatedCore
import Testing

/// Decodes a production-shaped activity page and checks each entry kind maps
/// to its feed row, including the rating each kind carries.
struct ActivityFeedMappingTests {
    @Test
    func mapsEveryEntryKind() throws {
        let page = try decodePage(results: [
            tastingSession(tastingId: 10, ratingBand: "very_good"),
            memberReview(entryId: "review:7", reviewId: 7, score: 88, notes: "Long finish."),
            criticReview(entryId: "critic:3", reviewId: 3, siteName: "Whiskyfun", reviewer: "Serge", score: 88),
            collectionAdd(entryId: "add:1", href: "/users/ava/library", name: "Library", totalItems: 3)
        ])

        let entries = page.results.flatMap { ActivityFeedMapping($0).entries }
        #expect(entries.map(\.id) == [
            "tasting:10",
            "member-review:7",
            "critic-review:3",
            "collection-add:add:1"
        ])

        guard case let .tasting(tasting) = entries[0] else {
            Issue.record("Expected a tasting")
            return
        }
        #expect(tasting.ratingBand == .veryGood)
        #expect(tasting.bottleName == "Ardbeg 10")

        guard case let .memberReview(review) = entries[1] else {
            Issue.record("Expected a member review")
            return
        }
        #expect(review.score == 88)
        #expect(review.ratingBand == .veryGood)
        #expect(review.notes == "Long finish.")
        #expect(review.username == "ava")
        #expect(review.bottle.id == "1")

        guard case let .criticReview(critic) = entries[2] else {
            Issue.record("Expected a critic review")
            return
        }
        #expect(critic.sourceName == "Whiskyfun")
        #expect(critic.byline == "Serge")
        #expect(critic.score?.ratingBand == .veryGood)
        #expect(critic.url == "https://example.com/review")

        guard case let .collectionAdd(add) = entries[3] else {
            Issue.record("Expected a collection add")
            return
        }
        #expect(add.isLibrary)
        #expect(add.actionText == "added 3 bottles to their library")
        #expect(add.hiddenBottleCount == 2)
        #expect(add.bottles.map(\.name) == ["Ardbeg 10"])
    }

    @Test
    func criticScoresOnOtherScalesHaveNoBand() throws {
        let page = try decodePage(results: [
            criticReview(
                entryId: "critic:4",
                reviewId: 4,
                siteName: "Dramface",
                reviewer: "Dramface",
                score: 8.5,
                scale: 10
            )
        ])

        let entries = page.results.flatMap { ActivityFeedMapping($0).entries }
        guard case let .criticReview(critic) = entries.first else {
            Issue.record("Expected a critic review")
            return
        }
        #expect(critic.score?.value == 8.5)
        #expect(critic.score?.scale == 10)
        #expect(critic.score?.ratingBand == nil)
        #expect(critic.byline == nil, "Reviewer matching the source is not a byline")
    }

    @Test
    func skipsFavoritesAndUnresolvedCriticReviews() throws {
        let page = try decodePage(results: [
            collectionAdd(entryId: "add:2", href: "/users/ava/favorites", name: "Favorites", totalItems: 1),
            criticReview(entryId: "critic:5", reviewId: 5, siteName: "Whiskyfun", score: 90, bottle: "null")
        ])

        let mappings = page.results.map(ActivityFeedMapping.init)
        #expect(mappings.flatMap(\.entries).isEmpty)
        #expect(mappings.flatMap(\.bottles).isEmpty)
    }

    @Test
    func collectsBottlesForCacheSeeding() throws {
        let page = try decodePage(results: [
            tastingSession(tastingId: 10, ratingBand: nil),
            memberReview(entryId: "review:7", reviewId: 7, score: 70, notes: nil)
        ])

        let bottles = page.results.flatMap { ActivityFeedMapping($0).bottles }
        #expect(bottles.map(\.id) == ["1", "1"])
        #expect(bottles.first?.fullName == "Ardbeg 10")
    }

    // MARK: - Fixture

    private func decodePage(results: [String]) throws -> Operations.listActivity.Output.Ok.Body.jsonPayload {
        let json = #"{"results":[\#(results.joined(separator: ","))],"rel":{"nextCursor":"page2","prevCursor":null}}"#
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Operations.listActivity.Output.Ok.Body.jsonPayload.self, from: Data(json.utf8))
    }

    private let date = "2026-09-18T10:00:00Z"
    private let user = #"{"id":42,"username":"ava","pictureUrl":null}"#

    private var bottle: String {
        let counts = #"{"mediocre":0,"good":0,"very_good":0,"outstanding":0,"unicorn":0}"#
        return #"""
        {"id":1,"peatedId":"b1","fullName":"Ardbeg 10","name":"10","imageUrl":"https://img/b1.png",
        "category":"single_malt",
        "brand":{"id":2,"peatedId":"e2","name":"Ardbeg","kind":"brand","totalTastings":1,
        "publicReviewAndTastingCount":1,"totalBottles":1,
        "isFollowing":false,"createdAt":"\#(date)","updatedAt":"\#(date)"},
        "medianScore":null,"minScore":null,"maxScore":null,"memberScoreCount":0,"externalScoreCount":0,
        "raterCount":0,"scoreCount":0,
        "reviewScoreBandCounts":\#(counts),"tastingBandCounts":\#(counts),"totalTastings":0,
        "publicReviewAndTastingCount":0,"notedReviewAndTastingCount":0,
        "createdAt":"\#(date)","updatedAt":"\#(date)","isFavorite":false,"isLibrary":false,"hasTasted":false}
        """#
    }

    private func tastingSession(tastingId: Int, ratingBand: String?) -> String {
        let band = ratingBand.map { "\"\($0)\"" } ?? "null"
        return #"""
        {"id":"session:1","type":"tasting_session","priority":"primary","startedAt":"\#(date)","lastActivityAt":"\#(date)",
        "createdBy":\#(user),"tastings":[{"id":\#(tastingId),"bottle":\#(bottle),"ratingBand":\#(band),"notes":"Peaty",
        "tags":["smoke"],"awards":[],"comments":0,"toasts":2,"createdAt":"\#(date)","createdBy":\#(user)}]}
        """#
    }

    private func memberReview(entryId: String, reviewId: Int, score: Int, notes: String?) -> String {
        let notesJSON = notes.map { "\"\($0)\"" } ?? "null"
        return #"""
        {"id":"\#(entryId)","type":"member_review","priority":"primary","createdAt":"\#(date)","createdBy":\#(user),
        "review":{"id":\#(reviewId),"bottleId":1,"score":\#(score),"notes":\#(notesJSON),"tags":["oak"],"imageUrl":null,
        "createdBy":\#(user),"createdAt":"\#(date)","updatedAt":"\#(date)","bottle":\#(bottle)}}
        """#
    }

    private func criticReview(
        entryId: String,
        reviewId: Int,
        siteName: String,
        reviewer: String? = nil,
        score value: Double,
        scale: Double = 100,
        bottle bottleJSON: String? = nil
    ) -> String {
        let reviewerJSON = reviewer.map { "\"\($0)\"" } ?? "null"
        return #"""
        {"id":"\#(entryId)","type":"critic_review","priority":"primary","createdAt":"\#(date)",
        "review":{"id":\#(reviewId),"name":"Ardbeg 10","url":"https://example.com/review",
        "site":{"id":9,"type":"whiskyfun","name":"\#(siteName)","imageUrl":"https://img/site.png"},
        "article":{"title":"Ardbeg 10 review","publishedAt":"\#(date)"},"reviewerName":\#(reviewerJSON),
        "nativeScore":{"value":\#(value),"scale":\#(scale),"display":"\#(value)"},
        "scoreContribution":{"value":null,"reason":"not_configured","guideUrl":null},
        "clip":"A classic.","extractedTags":["peat"],"bottle":\#(bottleJSON ?? bottle),
        "createdAt":"\#(date)","updatedAt":"\#(date)"}}
        """#
    }

    private func collectionAdd(entryId: String, href: String, name: String, totalItems: Int) -> String {
        #"""
        {"id":"\#(entryId)","type":"collection_add","priority":"secondary","createdAt":"\#(date)",
        "windowStart":"\#(date)","windowEnd":"\#(date)","createdBy":\#(user),
        "collection":{"id":5,"name":"\#(name)","totalBottles":\#(totalItems),"href":"\#(href)"},
        "items":[{"id":77,"bottle":\#(bottle),"imageUrl":"https://img/mine.png","hasTasted":false}],"totalItems":\#(totalItems)}
        """#
    }
}
