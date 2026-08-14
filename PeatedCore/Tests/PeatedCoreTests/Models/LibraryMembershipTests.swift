import Foundation
@testable import PeatedCore
import Testing

@MainActor
struct LibraryMembershipTests {
    @Test("Saving a bottle updates Library membership")
    func savingBottleUpdatesLibraryMembership() async {
        let repository = CollectionRepositoryStub()
        let model = BottleDetailModel(
            bottleId: "42",
            seed: makeBottle(isLibrary: false),
            collectionRepository: repository
        )

        await model.toggleLibrary()

        #expect(model.bottle?.isLibrary == true)
        let addedBottleIds = await repository.addedBottleIds
        #expect(addedBottleIds == ["42"])
    }

    @Test("Removing a bottle updates Library membership")
    func removingBottleUpdatesLibraryMembership() async {
        let repository = CollectionRepositoryStub()
        let model = BottleDetailModel(
            bottleId: "42",
            seed: makeBottle(isLibrary: true),
            collectionRepository: repository
        )

        await model.toggleLibrary()

        #expect(model.bottle?.isLibrary == false)
        let removedBottleIds = await repository.removedBottleIds
        #expect(removedBottleIds == ["42"])
    }

    @Test("A failed Library update restores the bottle")
    func failedLibraryUpdateRestoresBottle() async {
        let repository = CollectionRepositoryStub(shouldFailMutation: true)
        let model = BottleDetailModel(
            bottleId: "42",
            seed: makeBottle(isLibrary: false),
            collectionRepository: repository
        )

        await model.toggleLibrary()

        #expect(model.bottle?.isLibrary == false)
    }

    @Test("Cached bottles created before Library membership still decode")
    func legacyCachedBottleDecodes() throws {
        let json = #"""
        {
          "id": "42",
          "name": "12 Year",
          "fullName": "Example 12 Year",
          "brand": { "id": "7", "name": "Example" },
          "caskStrength": false,
          "singleCask": false,
          "avgRating": 0,
          "totalRatings": 0,
          "isFavorite": false,
          "hasTasted": false
        }
        """#

        let bottle = try JSONDecoder().decode(Bottle.self, from: Data(json.utf8))

        #expect(bottle.isLibrary == false)
    }

    private func makeBottle(isLibrary: Bool) -> Bottle {
        Bottle(
            id: "42",
            name: "12 Year",
            fullName: "Example 12 Year",
            brand: Brand(id: "7", name: "Example"),
            isLibrary: isLibrary
        )
    }
}
