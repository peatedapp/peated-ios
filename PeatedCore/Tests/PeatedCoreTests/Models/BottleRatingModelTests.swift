import Foundation
@testable import PeatedCore
import Testing

struct BottleRatingModelTests {
    @Test
    func scoresMapToThePublishedRatingBands() {
        #expect(TastingRatingBand(score: 0) == .mediocre)
        #expect(TastingRatingBand(score: 79) == .mediocre)
        #expect(TastingRatingBand(score: 80) == .good)
        #expect(TastingRatingBand(score: 85) == .veryGood)
        #expect(TastingRatingBand(score: 90) == .outstanding)
        #expect(TastingRatingBand(score: 95) == .unicorn)
        #expect(TastingRatingBand(score: 100) == .unicorn)
        #expect(TastingRatingBand(score: 101) == nil)
    }

    @Test
    func tastingCountsUseTheLowerMedianBand() {
        let counts = RatingBandCounts(mediocre: 1, good: 2, veryGood: 1, outstanding: 2)
        #expect(counts.total == 6)
        #expect(counts.lowerMedianBand == .good)
    }

    @Test
    func reviewMedianTakesPriorityForBottlePresentation() {
        let summary = BottleRatingSummary(
            medianScore: 92,
            memberScoreCount: 2,
            externalScoreCount: 1,
            tastingBandCounts: RatingBandCounts(unicorn: 10)
        )

        #expect(summary.presentedBand == .outstanding)
        #expect(summary.presentedCount == 3)
    }

    @Test
    func legacyBottleCacheDecodesWithoutRatingSummary() throws {
        let json = """
        {
          "id": "42",
          "name": "Uigeadail",
          "fullName": "Ardbeg Uigeadail",
          "brand": { "id": "7", "name": "Ardbeg" },
          "caskStrength": true,
          "singleCask": false,
          "avgRating": 1.25,
          "totalRatings": 4
        }
        """

        let bottle = try JSONDecoder().decode(Bottle.self, from: Data(json.utf8))

        #expect(bottle.ratingSummary.presentedCount == 0)
        #expect(bottle.totalTastings == 0)
        #expect(bottle.edition == nil)
    }

    @Test
    func currentBottleDetailsAndRatingSummaryRoundTrip() throws {
        let bottle = Bottle(
            id: "42",
            name: "Uigeadail",
            fullName: "Ardbeg Uigeadail",
            brand: Brand(id: "7", name: "Ardbeg"),
            edition: "Committee Release",
            vintageYear: 2009,
            bottlingYear: 2023,
            releaseYear: 2024,
            maturation: "Ex-bourbon and oloroso casks",
            distillers: [Brand(id: "8", name: "Ardbeg Distillery")],
            tastingNotes: BottleTastingNotes(nose: "Smoke", palate: "Fruit", finish: "Long"),
            ratingSummary: BottleRatingSummary(
                medianScore: 91,
                minimumScore: 86,
                maximumScore: 95,
                memberScoreCount: 5,
                externalScoreCount: 3,
                reviewBandCounts: RatingBandCounts(veryGood: 1, outstanding: 6, unicorn: 1),
                tastingBandCounts: RatingBandCounts(good: 2, veryGood: 5, outstanding: 3)
            ),
            totalTastings: 10
        )

        let data = try JSONEncoder().encode(bottle)
        let decoded = try JSONDecoder().decode(Bottle.self, from: data)

        #expect(decoded == bottle)
        #expect(decoded.ratingSummary.scoreCount == 8)
        #expect(decoded.totalTastings == 10)
    }
}
