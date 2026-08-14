@testable import Peated
import Testing

struct PeatedWebURLTests {
    @Test
    func bottleURL() {
        #expect(PeatedWebURL.bottle(id: "42").absoluteString == "https://peated.com/bottles/42")
    }

    @Test
    func tastingURL() {
        #expect(PeatedWebURL.tasting(id: "73").absoluteString == "https://peated.com/tastings/73")
    }
}
