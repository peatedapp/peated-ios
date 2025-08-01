import Testing
@testable import PeatedCore

struct PeatedCoreTests {
    @Test
    func testVersion() {
        #expect(PeatedCore.version == "1.0.0")
    }
}