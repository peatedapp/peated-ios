@testable import PeatedCore
import Testing

@MainActor
struct TastingActivityToastTests {
    @Test("Bottle activity applies the server toast state")
    func bottleActivityAppliesToastState() async {
        let tasting = TastingFeedItem.builder()
            .withId("42")
            .withToastCount(3)
            .build()
        let repository = ActivityTastingRepositoryStub(toggleResult: true)
        let model = BottleDetailModel(
            bottleId: tasting.bottleId,
            recentTastings: [tasting],
            tastingRepository: repository
        )

        await model.toggleToast(for: tasting.id)

        #expect(model.recentTastings.first?.hasToasted == true)
        #expect(model.recentTastings.first?.toastCount == 4)
        let toggledIds = await repository.toggledTastingIds
        #expect(toggledIds == [tasting.id])
    }

    @Test("Bottle activity restores its tasting when toast fails")
    func bottleActivityRestoresToastAfterFailure() async {
        let tasting = TastingFeedItem.builder()
            .withId("42")
            .withToastCount(3)
            .build()
        let repository = ActivityTastingRepositoryStub(
            toggleResult: true,
            shouldFailToggle: true
        )
        let model = BottleDetailModel(
            bottleId: tasting.bottleId,
            recentTastings: [tasting],
            tastingRepository: repository
        )

        await model.toggleToast(for: tasting.id)

        #expect(model.recentTastings == [tasting])
    }

    @Test("Entity activity applies the server toast state")
    func entityActivityAppliesToastState() async {
        let tasting = TastingFeedItem.builder()
            .withId("84")
            .withToastCount(3)
            .hasToasted()
            .build()
        let repository = ActivityTastingRepositoryStub(toggleResult: false)
        let model = EntityDetailModel(
            entityId: "12",
            recentTastings: [tasting],
            tastingRepository: repository
        )

        await model.toggleToast(for: tasting.id)

        #expect(model.recentTastings.first?.hasToasted == false)
        #expect(model.recentTastings.first?.toastCount == 2)
        let toggledIds = await repository.toggledTastingIds
        #expect(toggledIds == [tasting.id])
    }

    @Test("Entity activity restores its tasting when toast fails")
    func entityActivityRestoresToastAfterFailure() async {
        let tasting = TastingFeedItem.builder()
            .withId("84")
            .withToastCount(3)
            .hasToasted()
            .build()
        let repository = ActivityTastingRepositoryStub(
            toggleResult: false,
            shouldFailToggle: true
        )
        let model = EntityDetailModel(
            entityId: "12",
            recentTastings: [tasting],
            tastingRepository: repository
        )

        await model.toggleToast(for: tasting.id)

        #expect(model.recentTastings == [tasting])
    }
}
