import Testing
@testable import PeatedCore
import OpenAPIRuntime
import OpenAPIURLSession
import HTTPTypes

struct APIClientTests {
    @Test
    func testAPIClientCanBeCreated() throws {
        // This test verifies that the OpenAPI generator created the Client type
        let serverURL = try #require(URL(string: "https://api.peated.com/v1"))
        let transport = URLSessionTransport()
        
        // If this compiles, it means the OpenAPI generator worked
        let client = Client(
            serverURL: serverURL,
            transport: transport
        )
        
        // Verify the client exists
        #expect(client != nil)
    }
    
    @Test
    func testAPIClientHasExpectedMethods() throws {
        // This verifies that some expected API methods exist
        let serverURL = try #require(URL(string: "https://api.peated.com/v1"))
        let transport = URLSessionTransport()
        let client = Client(serverURL: serverURL, transport: transport)
        
        // These will only compile if the methods were generated
        // We're not actually calling them, just verifying they exist
        let _: (Operations.auth_period_login.Input) async throws -> Operations.auth_period_login.Output = client.auth_period_login
        let _: (Operations.bottles_period_list.Input) async throws -> Operations.bottles_period_list.Output = client.bottles_period_list
        let _: (Operations.tastings_period_list.Input) async throws -> Operations.tastings_period_list.Output = client.tastings_period_list
        
        // If we get here, the methods exist
        #expect(true)
    }
    
    @Test
    func testGeneratedTypesExist() {
        // Verify that some expected types were generated
        // These will fail to compile if the types don't exist
        
        // Components.Schemas should exist
        let _: Components.Schemas.Type? = nil
        
        // Operations should exist
        let _: Operations.Type? = nil
        
        // If this compiles, types were generated
        #expect(true)
    }
}