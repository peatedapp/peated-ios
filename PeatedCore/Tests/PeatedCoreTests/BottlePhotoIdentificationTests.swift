import PeatedAPI
@testable import PeatedCore
import Testing

struct BottlePhotoIdentificationTests {
    @Test
    func proposalBuildsManualCreationInput() {
        let proposal = BottlePhotoProposal(
            name: "Uigeadail",
            brandName: "Ardbeg",
            category: .singleMalt,
            statedAge: nil,
            abv: 54.2
        )

        #expect(proposal.fullName == "Ardbeg Uigeadail")
        #expect(proposal.createInput == CreateBottleInput(
            name: "Uigeadail",
            brandName: "Ardbeg",
            category: .singleMalt,
            abv: 54.2
        ))
    }

    @Test
    func labelFactsIncludeStructuredBottleDetails() {
        typealias Fields = Operations.identifyTastingBottleFromPhoto.Output.Ok.Body
            .jsonPayload.imageEvidencePayload.fieldCandidatesPayload

        let fields = Fields(
            brand: .init(value: "Ardbeg", confidence: 0.99),
            distillery: .init(value: ["Ardbeg Distillery"], confidence: 0.91),
            bottler: .init(value: "Official", confidence: 0.9),
            statedAge: .init(value: 10, confidence: 0.98),
            abv: .init(value: 46, confidence: 0.98),
            caskStrength: .init(value: false, confidence: 0.88),
            singleCask: .init(value: true, confidence: 0.87)
        )

        let facts = BottlePhotoIdentificationRepository.makeFacts(fields)

        #expect(facts.contains(BottlePhotoFact(label: "Brand", value: "Ardbeg")))
        #expect(facts.contains(BottlePhotoFact(label: "Distillers", value: "Ardbeg Distillery")))
        #expect(facts.contains(BottlePhotoFact(label: "Bottler", value: "Official")))
        #expect(facts.contains(BottlePhotoFact(label: "Age", value: "10 years")))
        #expect(facts.contains(BottlePhotoFact(label: "ABV", value: "46%")))
        #expect(facts.contains(BottlePhotoFact(label: "Cask Strength", value: "No")))
        #expect(facts.contains(BottlePhotoFact(label: "Single Cask", value: "Yes")))
    }
}
