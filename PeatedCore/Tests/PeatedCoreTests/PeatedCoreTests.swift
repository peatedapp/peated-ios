@testable import PeatedCore
import Testing

struct PeatedCoreTests {
    @Test
    func testVersion() {
        #expect(PeatedCore.version == "1.0.0")
    }
}
