import Foundation
import PeatedAPI
import HTTPTypes

struct AuthMiddleware: ClientMiddleware {
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var modifiedRequest = request
        
        // Try to get the token from keychain
        if let token = try? KeychainService.shared.getToken() {
            modifiedRequest.headerFields[.authorization] = "Bearer \(token)"
        }
        
        return try await next(modifiedRequest, body, baseURL)
    }
}