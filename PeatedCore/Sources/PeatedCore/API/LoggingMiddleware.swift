import Foundation
import HTTPTypes
import OpenAPIRuntime

/// Middleware that logs every API call and reports it as a telemetry span and
/// breadcrumb. Only the generated operation id, method, status, and duration
/// are recorded; paths, query strings, and bodies never leave the process.
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
        let method = request.method.rawValue

        // The generated operation id is stable and contains no user-supplied
        // path, query, or request-body values.
        let endpoint = operationID

        Logger.logAPIRequest(
            endpoint: endpoint,
            method: method
        )
        let span = Telemetry.startSpan(operation: "http.client", description: "\(method) \(operationID)")

        do {
            // Execute the request
            let (response, responseBody) = try await next(request, body, baseURL)

            // Calculate request duration
            let duration = Date().timeIntervalSince(startTime)
            var result = (response, responseBody)

            // If error status, try to read body for debugging and check for specific errors
            if response.status.code >= 400, let body = responseBody {
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
                    result = (response, HTTPBody(data))
                } catch let error as APIError {
                    // Re-throw our custom errors
                    throw error
                } catch {
                    // Failed to read error body, continue with original response
                }
            }

            Logger.logAPIResponse(
                endpoint: endpoint,
                statusCode: response.status.code,
                duration: duration
            )
            Self.record(
                operationID: operationID,
                method: method,
                statusCode: response.status.code,
                duration: duration,
                span: span
            )

            return result

        } catch {
            // Calculate request duration even for errors
            let duration = Date().timeIntervalSince(startTime)

            // Log error response
            Logger.logAPIError(
                endpoint: endpoint,
                error: error,
                method: method,
                duration: duration
            )
            Self.record(
                operationID: operationID,
                method: method,
                error: error,
                duration: duration,
                span: span
            )

            // Re-throw the error
            throw error
        }
    }

    private static func record(
        operationID: String,
        method: String,
        statusCode: Int,
        duration: TimeInterval,
        span: (any TelemetrySpan)?
    ) {
        span?.setData(.int(statusCode), key: "http.response.status_code")
        span?.finish(status: TelemetrySpanStatus(httpStatus: statusCode))
        Telemetry.addBreadcrumb(TelemetryBreadcrumb(
            category: "http",
            message: "\(method) \(operationID)",
            level: statusCode >= 400 ? .warning : .info,
            data: [
                "operation": .string(operationID),
                "method": .string(method),
                "status_code": .int(statusCode),
                "duration_ms": .int(Int(duration * 1000))
            ]
        ))
    }

    private static func record(
        operationID: String,
        method: String,
        error: any Error,
        duration: TimeInterval,
        span: (any TelemetrySpan)?
    ) {
        let cancelled = error is CancellationError || (error as? URLError)?.code == .cancelled
        span?.finish(status: cancelled ? .cancelled : .unknownError)
        Telemetry.addBreadcrumb(TelemetryBreadcrumb(
            category: "http",
            message: "\(method) \(operationID)",
            level: cancelled ? .info : .error,
            data: [
                "operation": .string(operationID),
                "method": .string(method),
                "error_kind": .string(String(describing: type(of: error))),
                "duration_ms": .int(Int(duration * 1000))
            ]
        ))
    }
}
