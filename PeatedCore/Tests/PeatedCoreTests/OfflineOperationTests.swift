import Foundation
@testable import PeatedCore
import Testing

struct OfflineOperationTests {
    @Test
    func createTastingEncodesPayload() throws {
        let location = CreateTastingPayload.Location(
            name: "Edinburgh",
            latitude: 55.9533,
            longitude: -3.1883
        )

        let operation = try OfflineOperation.createTasting(
            bottleId: "bottle-1",
            rating: 4.5,
            notes: "Rich and smoky",
            servingStyle: "neat",
            tags: ["smoky"],
            imageData: Data([1, 2, 3]),
            location: location
        )
        let payload = try JSONDecoder().decode(CreateTastingPayload.self, from: operation.payload)

        #expect(operation.type == .createTasting)
        #expect(payload.bottleId == "bottle-1")
        #expect(payload.rating == 4.5)
        #expect(payload.notes == "Rich and smoky")
        #expect(payload.servingStyle == "neat")
        #expect(payload.tags == ["smoky"])
        #expect(payload.imageData == Data([1, 2, 3]))
        #expect(payload.location?.name == "Edinburgh")
        #expect(payload.location?.latitude == 55.9533)
        #expect(payload.location?.longitude == -3.1883)
    }

    @Test
    func createTastingRejectsNonFiniteRating() {
        #expect(throws: EncodingError.self) {
            try OfflineOperation.createTasting(
                bottleId: "bottle-1",
                rating: .nan,
                notes: nil,
                servingStyle: nil,
                tags: [],
                imageData: nil,
                location: nil
            )
        }
    }

    @Test
    func toggleToastEncodesPayload() throws {
        let operation = try OfflineOperation.toggleToast(tastingId: "tasting-1", isToasted: true)
        let payload = try JSONDecoder().decode(ToggleToastPayload.self, from: operation.payload)

        #expect(operation.type == .toggleToast)
        #expect(payload.tastingId == "tasting-1")
        #expect(payload.isToasted)
    }

    @Test
    func addCommentEncodesPayload() throws {
        let operation = try OfflineOperation.addComment(tastingId: "tasting-1", text: "Cheers!")
        let payload = try JSONDecoder().decode(AddCommentPayload.self, from: operation.payload)

        #expect(operation.type == .addComment)
        #expect(payload.tastingId == "tasting-1")
        #expect(payload.text == "Cheers!")
    }

    @Test(arguments: [true, false])
    func followUserEncodesPayload(isFollowing: Bool) throws {
        let operation = try OfflineOperation.followUser(userId: "user-1", isFollowing: isFollowing)
        let payload = try JSONDecoder().decode(FollowUserPayload.self, from: operation.payload)

        #expect(operation.type == (isFollowing ? .followUser : .unfollowUser))
        #expect(payload.userId == "user-1")
        #expect(payload.isFollowing == isFollowing)
    }
}
