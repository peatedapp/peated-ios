import Foundation
@testable import PeatedCore
import Testing

struct APIClientTests {
    @Test
    func apiClientCanBeCreated() async throws {
        let serverURL = try #require(URL(string: "https://api.peated.com/v1"))
        let client = APIClient(serverURL: serverURL)

        _ = await client.generatedClient
    }
}
