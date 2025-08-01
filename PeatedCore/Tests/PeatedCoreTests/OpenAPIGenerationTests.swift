import Testing
import PeatedCore
import OpenAPIRuntime
import OpenAPIURLSession

@Suite
struct OpenAPIGenerationTests {
  @Test
  func testAPIClientExists() async throws {
    // This test simply verifies that the API client is being generated
    let manager = AuthenticationManagerTemp()
    manager.printAvailableMethods()
    
    #expect(manager.apiClient.generatedClient != nil)
  }
}