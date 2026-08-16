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
        #expect(brand._type == [.brand])
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
    }

    @Test
    func categoriesMatchServerValues() {
        #expect(BottleCategory.allCases.map(\.rawValue) == [
            "blend",
            "bourbon",
            "rye",
            "single_grain",
            "single_malt",
            "single_pot_still",
            "spirit"
        ])
    }
}
