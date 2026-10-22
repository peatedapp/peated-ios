@testable import PeatedCore
import Testing

struct BottleCreationTests {
    @Test
    func createPayloadMapsSupportedFields() throws {
        let payload = BottleRepository.makeCreatePayload(CreateBottleInput(
            name: "Uigeadail",
            brandName: "Ardbeg",
            category: .singleMalt,
            statedAge: 12,
            abv: 54.2
        ))

        #expect(payload.name == "Uigeadail")
        #expect(payload.category == .single_malt)
        #expect(payload.statedAge == 12)
        #expect(payload.abv == 54.2)

        let brand = try #require(payload.brand?.value1)
        #expect(brand.name == "Ardbeg")
        #expect(brand.kind == .brand)
    }

    @Test
    func createPayloadLeavesOptionalFieldsUnset() {
        let payload = BottleRepository.makeCreatePayload(CreateBottleInput(
            name: "Uigeadail",
            brandName: "Ardbeg"
        ))

        #expect(payload.category == nil)
        #expect(payload.statedAge == nil)
        #expect(payload.abv == nil)
        #expect(payload.noAgeStatement == nil)
        #expect(payload.edition == nil)
        #expect(payload.distillers == nil)
        #expect(payload.singleCask == nil)
        #expect(payload.caskStrength == nil)
        #expect(payload.vintageYear == nil)
        #expect(payload.releaseYear == nil)
    }

    @Test
    func noAgeStatementDropsStatedAge() {
        let payload = BottleRepository.makeCreatePayload(CreateBottleInput(
            name: "Uigeadail",
            brandName: "Ardbeg",
            statedAge: 10,
            noAgeStatement: true
        ))

        #expect(payload.noAgeStatement == true)
        #expect(payload.statedAge == nil)
    }

    @Test
    func createPayloadMapsReleaseDetails() {
        let payload = BottleRepository.makeCreatePayload(CreateBottleInput(
            name: "Uigeadail",
            brandName: "Ardbeg",
            edition: "Batch 24",
            singleCask: true,
            caskStrength: true,
            vintageYear: 2009,
            releaseYear: 2024
        ))

        #expect(payload.edition == "Batch 24")
        #expect(payload.singleCask == true)
        #expect(payload.caskStrength == true)
        #expect(payload.vintageYear == 2009)
        #expect(payload.releaseYear == 2024)
    }

    @Test
    func createPayloadMapsExistingAndNewDistillers() throws {
        let payload = BottleRepository.makeCreatePayload(CreateBottleInput(
            name: "Blended Malt",
            brandName: "Compass Box",
            distillers: [
                .existing(id: 42, name: "Ardbeg"),
                .new(name: "Caol Ila")
            ]
        ))

        let distillers = try #require(payload.distillers)
        #expect(distillers.count == 2)
        #expect(distillers[0].value2 == 42)
        #expect(distillers[0].value1 == nil)
        let newDistiller = try #require(distillers[1].value1)
        #expect(newDistiller.name == "Caol Ila")
        #expect(newDistiller.kind == .distillery)
    }

    @Test
    func categoriesMatchServerValues() {
        #expect(BottleCategory.allCases.map(\.rawValue) == [
            "blend",
            "blended_grain",
            "blended_malt",
            "bourbon",
            "corn",
            "rye",
            "single_grain",
            "single_malt",
            "single_pot_still",
            "wheat"
        ])
    }

    @Test
    func categoryPickerLabelsMatchDisplayedLabels() {
        #expect(BottleCategory.singleMalt.displayName == "Single Malt")
        #expect(BottleCategory.blend.displayName == "Blended Whisky")
    }
}
