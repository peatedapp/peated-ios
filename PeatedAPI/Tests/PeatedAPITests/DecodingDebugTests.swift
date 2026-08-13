import Foundation
@testable import PeatedAPI
import Testing

@Suite("Response Decoding Tests")
struct ResponseDecodingTests {
    @Test("Decode an empty tasting page")
    func decodeEmptyTastingPage() throws {
        let data = Data(
            #"{"results":[],"rel":{"nextCursor":42,"prevCursor":null}}"#.utf8
        )

        let decoded = try JSONDecoder().decode(
            Operations.listTastings.Output.Ok.Body.jsonPayload.self,
            from: data
        )

        #expect(decoded.results.isEmpty)
        #expect(decoded.rel.nextCursor == 42)
        #expect(decoded.rel.prevCursor == nil)
    }
}
