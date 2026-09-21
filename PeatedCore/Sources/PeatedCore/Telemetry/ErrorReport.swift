import Foundation
import OpenAPIRuntime

/// A privacy-safe projection of a failure for telemetry.
///
/// Building a report never copies URLs, query strings, request or response
/// bodies, or user content. It keeps type names, coding keys, status codes,
/// and the generated API operation id. `init?` returns `nil` for expected
/// failures so they never become Sentry issues.
public struct ErrorReport: Sendable, Equatable {
    /// The feature that owns the failing flow, such as `feed` or `auth`.
    public var feature: String
    /// The action inside the feature, such as `load` or `toggle_toast`.
    public var operation: String
    /// Stable, low-cardinality classification such as `decoding.key_not_found`.
    public var kind: String
    /// Short human-readable description. Contains type and field names only.
    public var summary: String
    /// Generated OpenAPI operation id when the failure came from the API client.
    public var apiOperation: String?
    /// Static cause reported by the OpenAPI runtime, such as a deserialization failure.
    public var apiCause: String?
    public var httpStatus: Int?
    public var attributes: [String: TelemetryAttribute]

    /// Returns `nil` when the error is expected and must not create an issue.
    public init?(
        error: any Error,
        feature: String,
        operation: String,
        attributes: [String: TelemetryAttribute] = [:]
    ) {
        var apiOperation: String?
        var apiCause: String?
        var httpStatus: Int?
        var cause: any Error = error

        // Unwrap client and API wrappers down to the error that explains the failure.
        while true {
            if let clientError = cause as? ClientError {
                apiOperation = clientError.operationID
                apiCause = clientError.causeDescription
                httpStatus = clientError.response?.status.code
                cause = clientError.underlyingError
            } else if case let APIError.networkError(inner) = cause {
                cause = inner
            } else if case let APIError.decodingError(inner) = cause {
                cause = inner
            } else {
                break
            }
        }

        guard Self.isReportable(cause) else { return nil }

        let description = Self.describe(cause)
        self.feature = feature
        self.operation = operation
        kind = description.kind
        summary = description.summary
        self.apiOperation = apiOperation
        self.apiCause = apiCause
        self.httpStatus = httpStatus
        self.attributes = attributes
    }

    // MARK: - Classification

    /// Expected control flow, offline state, rejected input, and expired sessions
    /// are not issues. Everything else is.
    static func isReportable(_ error: any Error) -> Bool {
        if error is CancellationError {
            return false
        }

        if let urlError = error as? URLError {
            return !expectedURLErrorCodes.contains(urlError.code)
        }

        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized, .notFound, .requestFailed, .timeout, .termsAcceptanceRequired:
                return false
            case .invalidResponse, .unexpectedResponse, .serverError, .networkError, .decodingError, .notImplemented:
                return true
            }
        }

        return true
    }

    private static let expectedURLErrorCodes: Set<URLError.Code> = [
        .cancelled,
        .timedOut,
        .notConnectedToInternet,
        .networkConnectionLost,
        .dataNotAllowed,
        .internationalRoamingOff,
        .cannotFindHost,
        .cannotConnectToHost,
        .dnsLookupFailed
    ]

    // MARK: - Safe descriptions

    static func describe(_ error: any Error) -> (kind: String, summary: String) {
        if let decodingError = error as? DecodingError {
            return describe(decodingError)
        }

        if let urlError = error as? URLError {
            return ("url.\(urlError.code.rawValue)", "URL error \(urlError.code.rawValue)")
        }

        if let apiError = error as? APIError {
            return describe(apiError)
        }

        let typeName = String(reflecting: type(of: error))
        // Payload-free enum cases carry no content, so the case name is safe.
        // Anything with associated values or stored properties is reduced to
        // its type plus the bridged NSError code.
        if Mirror(reflecting: error).children.isEmpty {
            return (typeName, String(reflecting: error))
        }
        let nsError = error as NSError
        return (typeName, "\(nsError.domain) code \(nsError.code)")
    }

    private static func describe(_ error: DecodingError) -> (kind: String, summary: String) {
        switch error {
        case let .keyNotFound(key, context):
            ("decoding.key_not_found", "Missing key '\(key.stringValue)' at \(path(context.codingPath))")
        case let .typeMismatch(type, context):
            ("decoding.type_mismatch", "Expected \(type) at \(path(context.codingPath)): \(context.debugDescription)")
        case let .valueNotFound(type, context):
            ("decoding.value_not_found", "Missing \(type) value at \(path(context.codingPath))")
        case let .dataCorrupted(context):
            ("decoding.data_corrupted", "Corrupted data at \(path(context.codingPath)): \(context.debugDescription)")
        @unknown default:
            ("decoding.unknown", "Decoding failed")
        }
    }

    private static func describe(_ error: APIError) -> (kind: String, summary: String) {
        switch error {
        case .invalidResponse:
            ("api.invalid_response", "Invalid API response")
        case let .unexpectedResponse(status):
            ("api.unexpected_response", "Unexpected API response \(status)")
        case let .serverError(status, _):
            ("api.server_error", "API server error \(status)")
        case .notImplemented:
            ("api.not_implemented", "API feature not implemented")
        case .unauthorized, .notFound, .requestFailed, .timeout, .termsAcceptanceRequired,
             .networkError, .decodingError:
            ("api.\(String(describing: error).prefix { $0 != "(" })", "API error")
        }
    }

    /// Formats a coding path like `results[0].bottle.avgRating`.
    private static func path(_ codingPath: [any CodingKey]) -> String {
        guard !codingPath.isEmpty else { return "<root>" }
        var result = ""
        for key in codingPath {
            if let index = key.intValue {
                result += "[\(index)]"
            } else {
                result += result.isEmpty ? key.stringValue : ".\(key.stringValue)"
            }
        }
        return result
    }
}
