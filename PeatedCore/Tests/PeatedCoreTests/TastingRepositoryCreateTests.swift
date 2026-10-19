import Foundation
@testable import PeatedAPI
@testable import PeatedCore
import Testing

struct TastingRepositoryCreateTests {
    @Test
    func sendsWhenTheDramWasHadAndTheIdempotencyKey() throws {
        let tastedAt = Date(timeIntervalSince1970: 1_785_000_000)
        let body = try TastingRepository.makeCreateBody(CreateTastingInput(
            bottleId: "42",
            idempotencyKey: "post-1",
            tastedAt: tastedAt
        ))

        #expect(body.bottle == 42)
        #expect(body.tastedAt == tastedAt)
        #expect(body.idempotencyKey == "post-1")
    }

    @Test
    func leavesTheTastedTimeToTheServerWhenUnknown() throws {
        let body = try TastingRepository.makeCreateBody(CreateTastingInput(
            bottleId: "42",
            idempotencyKey: "post-1"
        ))

        #expect(body.tastedAt == nil)
    }

    @Test
    func rejectsBottlesWithoutANumericId() {
        #expect(throws: APIError.self) {
            try TastingRepository.makeCreateBody(CreateTastingInput(
                bottleId: "springbank-15",
                idempotencyKey: "post-1"
            ))
        }
    }
}
