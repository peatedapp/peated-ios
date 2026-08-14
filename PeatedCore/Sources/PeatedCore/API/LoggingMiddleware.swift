import Foundation
import HTTPTypes
import OpenAPIRuntime

/// Middleware to automatically log all API requests and responses
public struct LoggingMiddleware: ClientMiddleware {
    public init() {}

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let startTime = Date()

        // Extract endpoint from URL path
        let endpoint = request.path ?? operationID

        // Extract query parameters for logging context
        var context: [String: Any] = [:]
        if let query = request.headerFields[.contentType]?.description {
            context["contentType"] = query
        }

        Logger.logAPIRequest(
            endpoint: endpoint,
            method: request.method.rawValue,
            parameters: context.isEmpty ? nil : context
        )

        do {
            // Execute the request
            let (response, responseBody) = try await next(request, body, baseURL)

            // Calculate request duration
            let duration = Date().timeIntervalSince(startTime)

            // If error status, try to read body for debugging and check for specific errors
            if response.status.code >= 400 {
                if let body = responseBody {
                    do {
                        let data = try await Data(collecting: body, upTo: 10000)
                        if let bodyString = String(data: data, encoding: .utf8) {
                            // Check for "Terms acceptance required" error
                            if response.status.code == 403, bodyString.contains("Terms acceptance required") {
                                // Set flag on main actor to trigger UI
                                Task { @MainActor in
                                    AuthenticationManager.shared.needsTermsAcceptance = true
                                }
                                throw APIError.termsAcceptanceRequired
                            }
                        }
                        // Recreate the body since we consumed it
                        let newBody = HTTPBody(data)
                        Logger.logAPIResponse(
                            endpoint: endpoint,
                            statusCode: response.status.code,
                            duration: duration
                        )
                        return (response, newBody)
                    } catch let error as APIError {
                        // Re-throw our custom errors
                        throw error
                    } catch {
                        // Failed to read error body, continue with original response
                    }
                }
            }

            // Log successful response
            Logger.logAPIResponse(
                endpoint: endpoint,
                statusCode: response.status.code,
                duration: duration
            )

            return (response, responseBody)

        } catch {
            // Calculate request duration even for errors
            let duration = Date().timeIntervalSince(startTime)

            // Log error response
            Logger.logAPIError(
                endpoint: endpoint,
                error: error,
                context: [
                    "method": request.method.rawValue,
                    "duration": duration
                ]
            )

            // Re-throw the error
            throw error
        }
    }
}
