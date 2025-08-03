import Foundation
import OpenAPIRuntime
import HTTPTypes

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
    
    // Log the outgoing request
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