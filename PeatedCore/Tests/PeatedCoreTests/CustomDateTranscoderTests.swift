import Foundation
@testable import PeatedCore
import Testing

struct CustomDateTranscoderTests {
    @Test
    func fractionalDateRoundTrips() throws {
        let transcoder = CustomDateTranscoder()
        let original = Date(timeIntervalSince1970: 1_700_000_000.125)

        let encoded = try transcoder.encode(original)
        let decoded = try transcoder.decode(encoded)

        #expect(abs(decoded.timeIntervalSince(original)) < 0.001)
    }

    @Test
    func dateWithoutFractionalSecondsDecodes() throws {
        let transcoder = CustomDateTranscoder()

        let decoded = try transcoder.decode("2024-01-02T03:04:05Z")

        #expect(decoded.timeIntervalSince1970 == 1_704_164_645)
    }

    @Test
    func invalidDateThrows() {
        let transcoder = CustomDateTranscoder()

        #expect(throws: DecodingError.self) {
            try transcoder.decode("not-a-date")
        }
    }
}
