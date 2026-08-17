@testable import Peated
import Testing

struct BottleLabelSearchTextTests {
    @Test
    func buildsQueryInLabelReadingOrder() {
        let query = BottleLabelSearchText.query(from: [
            .init(text: "Uigeadail", x: 15, y: 80),
            .init(text: "Ardbeg", x: 10, y: 20),
            .init(text: "Islay Single Malt", x: 10, y: 120)
        ])

        #expect(query == "Ardbeg Uigeadail Islay Single Malt")
    }

    @Test
    func removesDuplicateAndBlankRecognitionResults() {
        let query = BottleLabelSearchText.query(from: [
            .init(text: "  ARDBEG  ", x: 10, y: 10),
            .init(text: "ardbeg", x: 10, y: 20),
            .init(text: "\n\t", x: 10, y: 30),
            .init(text: "Uigeadail", x: 10, y: 40)
        ])

        #expect(query == "ARDBEG Uigeadail")
    }

    @Test
    func limitsNoisyLabelsToUsefulSearchLength() {
        let query = BottleLabelSearchText.query(
            from: [
                .init(text: "Ardbeg", x: 0, y: 0),
                .init(text: "Uigeadail", x: 0, y: 10),
                .init(text: "Islay Single Malt Scotch Whisky", x: 0, y: 20),
                .init(text: "Non chill-filtered", x: 0, y: 30),
                .init(text: "Additional packaging copy", x: 0, y: 40)
            ],
            maximumLines: 4
        )

        #expect(query == "Ardbeg Uigeadail Islay Single Malt Scotch Whisky Non chill-filtered")
    }

    @Test
    func skipsLinesThatWouldExceedTheCharacterLimit() {
        let query = BottleLabelSearchText.query(
            from: [
                .init(text: "Ardbeg", x: 0, y: 0),
                .init(text: "An extremely long line of unrelated packaging text", x: 0, y: 10),
                .init(text: "Ten", x: 0, y: 20)
            ],
            maximumCharacters: 16
        )

        #expect(query == "Ardbeg Ten")
    }
}
