import Foundation
import PeatedAPI
import OpenAPIRuntime

// MARK: - Unified Error Types

public enum APIError: LocalizedError {
  case invalidResponse
  case requestFailed(String)
  case unexpectedResponse(Int)
  case unauthorized
  case notFound
  case serverError(Int, String?)
  case networkError(Error)
  case decodingError(Error)
  case timeout
  
  public var errorDescription: String? {
    switch self {
    case .invalidResponse:
      return "Invalid server response"
    case .requestFailed(let message):
      return message
    case .unexpectedResponse(let statusCode):
      return "Unexpected response: \(statusCode)"
    case .unauthorized:
      return "Authentication required"
    case .notFound:
      return "Resource not found"
    case .serverError(let code, let message):
      return message ?? "Server error (\(code))"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .decodingError:
      return "Unable to process response"
    case .timeout:
      return "Request timed out"
    }
  }
}

// MARK: - Response Handler Protocol

public protocol APIResponseHandler {
  func handleResponse<T>(_ response: T) throws -> T
}

// MARK: - Generic Response Handling

public enum APIResponseHelper {
  
  /// Handle common response patterns for operations that return Ok/Error responses
  public static func handleStandardResponse<SuccessBody>(
    _ response: Any,
    onOk: (SuccessBody) throws -> Void
  ) throws {
    // This is a simplified example - in reality, each operation has its own response type
    // You would need to handle each operation's specific response cases
    
    // For now, we'll throw a generic error if not handled
    throw APIError.invalidResponse
  }
  
  /// Extract JSON payload from successful responses
  public static func extractJSON<Response, JSONType>(
    from response: Response,
    okPath: KeyPath<Response, Any?>,
    jsonPath: KeyPath<Any, JSONType?>
  ) throws -> JSONType {
    guard let okResponse = response[keyPath: okPath],
          let jsonPayload = okResponse[keyPath: jsonPath] else {
      throw APIError.invalidResponse
    }
    return jsonPayload
  }
}

// MARK: - Response Extensions for Common Patterns

extension Operations.login.Output {
  public func extractPayload() throws -> Operations.login.Output.Ok.Body.jsonPayload {
    switch self {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        return payload
      }
    case .badRequest:
      throw APIError.requestFailed("Invalid credentials")
    case .unauthorized:
      throw APIError.unauthorized
    case .forbidden:
      throw APIError.requestFailed("Forbidden")
    case .notFound:
      throw APIError.notFound
    case .conflict:
      throw APIError.requestFailed("Conflict")
    case .contentTooLarge:
      throw APIError.requestFailed("Content too large")
    case .internalServerError:
      throw APIError.serverError(500, "Internal server error")
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    }
  }
}

extension Operations.listTastings.Output {
  public func extractPayload() throws -> Operations.listTastings.Output.Ok.Body.jsonPayload {
    switch self {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        return payload
      }
    case .badRequest:
      throw APIError.requestFailed("Bad request")
    case .unauthorized:
      throw APIError.unauthorized
    case .forbidden:
      throw APIError.requestFailed("Forbidden")
    case .notFound:
      throw APIError.notFound
    case .conflict:
      throw APIError.requestFailed("Conflict")
    case .contentTooLarge:
      throw APIError.requestFailed("Content too large")
    case .internalServerError:
      throw APIError.serverError(500, "Internal server error")
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    }
  }
}

extension Operations.listUserBadges.Output {
  public func extractPayload() throws -> Operations.listUserBadges.Output.Ok.Body.jsonPayload {
    switch self {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        return payload
      }
    case .badRequest:
      throw APIError.requestFailed("Bad request")
    case .unauthorized:
      throw APIError.unauthorized
    case .forbidden:
      throw APIError.requestFailed("Forbidden")
    case .notFound:
      throw APIError.notFound
    case .conflict:
      throw APIError.requestFailed("Conflict")
    case .contentTooLarge:
      throw APIError.requestFailed("Content too large")
    case .internalServerError:
      throw APIError.serverError(500, "Internal server error")
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    }
  }
}