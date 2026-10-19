import Foundation
@testable import PeatedCore
import Testing

struct TastedDateTests {
    private let postedAt = Date(timeIntervalSince1970: 1_785_400_000)
    private let tastedAt = Date(timeIntervalSince1970: 1_785_000_000)

    @Test
    func showsWhenTheDramWasHadRatherThanWhenItWasPosted() {
        let tasting = TastingFeedItemBuilder()
            .withCreatedAt(postedAt)
            .withTastedAt(tastedAt)
            .build()

        #expect(tasting.tastedDate == tastedAt)
        #expect(TastingDetail(from: tasting).tastedAt == tastedAt)
    }

    @Test
    func readsTastingsCachedBeforeTheServerSentTastedAt() throws {
        let cached = TastingFeedItemBuilder()
            .withCreatedAt(postedAt)
            .build()
        var json = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(cached)) as? [String: Any]
        )
        json.removeValue(forKey: "tastedAt")

        let decoded = try JSONDecoder().decode(
            TastingFeedItem.self,
            from: JSONSerialization.data(withJSONObject: json)
        )

        #expect(decoded.tastedAt == nil)
        #expect(decoded.tastedDate == postedAt)
    }

    @Test
    func keepsTheTastedTimeThroughAToast() {
        let tasting = TastingFeedItemBuilder()
            .withCreatedAt(postedAt)
            .withTastedAt(tastedAt)
            .build()

        #expect(tasting.updatingToast(to: true).tastedAt == tastedAt)
    }
}
