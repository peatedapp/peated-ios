@testable import PeatedCore
import Testing

struct ActivityPreviewTests {
    @Test
    func collapsesWhitespaceAndKeepsShortText() {
        #expect("  Peaty,\n  long   finish. ".activityPreview() == "Peaty, long finish.")
    }

    @Test
    func returnsNilForBlankText() {
        #expect("   \n ".activityPreview() == nil)
    }

    @Test
    func cutsAtAWordBoundaryWithAnEllipsis() {
        let words = Array(repeating: "smoke", count: 40).joined(separator: " ")

        let preview = "smoke".activityPreview(limit: 3)
        #expect(preview == "smo…")

        let longPreview = words.activityPreview(limit: 20)
        #expect(longPreview == "smoke smoke smoke…")
    }
}
