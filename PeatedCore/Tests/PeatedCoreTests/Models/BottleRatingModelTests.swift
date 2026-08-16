import Foundation
@testable import PeatedCore
import Testing

struct BottleRatingModelTests {
    @Test
    func ratingValuesMatchTheSimpleRatingContract() {
        #expect(RatingValue(rating: -1) == .pass)
        #expect(RatingValue(rating: 1) == .sip)
        #expect(RatingValue(rating: 2) == .savor)
        #expect(RatingValue(rating: 1.5) == nil)
        #expect(RatingValue.savor.iconCount == 2)
        #expect(RatingValue.sip.description == "Enjoyable, would drink again")
    }

    @Test
    func legacyBottleCacheDecodesWithoutNewFields() throws {
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

        #expect(bottle.avgRating == 1.25)
        #expect(bottle.totalRatings == 4)
        #expect(bottle.totalTastings == 4)
        #expect(bottle.ratingStats.total == 4)
        #expect(bottle.edition == nil)
    }

    @Test
    func currentBottleDetailsAndRatingStatsRoundTrip() throws {
        let bottle = Bottle(
            id: "42",
            name: "Uigeadail",
            fullName: "Ardbeg Uigeadail",
            brand: Brand(id: "7", name: "Ardbeg"),
            edition: "Committee Release",
            vintageYear: 2009,
            releaseYear: 2024,
            caskType: "oloroso",
            distillers: [Brand(id: "8", name: "Ardbeg Distillery")],
            tastingNotes: BottleTastingNotes(nose: "Smoke", palate: "Fruit", finish: "Long"),
            avgRating: 1.5,
            ratingStats: BottleRatingStats(
                pass: 1,
                sip: 2,
                savor: 5,
                total: 8,
                average: 1.5,
                percentages: .init(pass: 12.5, sip: 25, savor: 62.5)
            ),
            totalTastings: 10
        )

        let data = try JSONEncoder().encode(bottle)
        let decoded = try JSONDecoder().decode(Bottle.self, from: data)

        #expect(decoded == bottle)
        #expect(decoded.totalRatings == 8)
        #expect(decoded.totalTastings == 10)
    }
}
