import Foundation
import HTTPTypes
import OpenAPIRuntime
@testable import PeatedCore
import Testing

/// These tests swap the process-wide reporter, so they run one at a time.
@Suite(.serialized)
struct TelemetryTests {
    private func withRecorder(_ body: (RecordingTelemetryReporter) async throws -> Void) async rethrows {
        let recorder = RecordingTelemetryReporter()
        Telemetry.install(recorder)
        defer { Telemetry.install(NoopTelemetryReporter()) }
        try await body(recorder)
    }

    @Test
    func captureDropsExpectedFailures() async {
        await withRecorder { recorder in
            Telemetry.capture(CancellationError(), feature: "telemetry_test", operation: "expected")
            Telemetry.capture(URLError(.notConnectedToInternet), feature: "telemetry_test", operation: "expected")
            Telemetry.capture(APIError.unauthorized, feature: "telemetry_test", operation: "expected")

            #expect(recorder.reports.filter { $0.feature == "telemetry_test" }.isEmpty)
        }
    }

    @Test
    func captureForwardsUnexpectedFailuresOnce() async throws {
        try await withRecorder { recorder in
            let sent = Telemetry.capture(
                APIError.serverError(500, nil),
                feature: "telemetry_test",
                operation: "unexpected",
                attributes: ["retry_count": .int(3)]
            )

            let reports = recorder.reports.filter { $0.feature == "telemetry_test" }
            #expect(reports.count == 1)
            let report = try #require(reports.first)
            #expect(report == sent)
            #expect(report.operation == "unexpected")
            #expect(report.kind == "api.server_error")
            #expect(report.attributes["retry_count"] == .int(3))
        }
    }

    @Test
    func middlewareRecordsOperationWithoutURL() async throws {
        try await withRecorder { recorder in
            let middleware = LoggingMiddleware()
            let request = HTTPRequest(
                method: .get,
                scheme: "https",
                authority: "api.peated.com",
                path: "/v1/search?query=secret%20dram"
            )
            let baseURL = try #require(URL(string: "https://api.peated.com/v1"))

            _ = try await middleware.intercept(
                request,
                body: nil,
                baseURL: baseURL,
                operationID: "search"
            ) { _, _, _ in
                (HTTPResponse(status: .ok), nil)
            }

            let breadcrumb = try #require(
                recorder.breadcrumbs.first { $0.category == "http" && $0.message == "GET search" }
            )
            #expect(breadcrumb.level == .info)
            #expect(breadcrumb.data["operation"] == .string("search"))
            #expect(breadcrumb.data["status_code"] == .int(200))
            #expect(!"\(breadcrumb)".contains("secret"))
            #expect(!"\(breadcrumb)".contains("/v1/"))
        }
    }

    @Test
    func middlewareRecordsTransportFailures() async throws {
        try await withRecorder { recorder in
            let middleware = LoggingMiddleware()
            let request = HTTPRequest(method: .post, scheme: "https", authority: "api.peated.com", path: "/v1/tastings")
            let baseURL = try #require(URL(string: "https://api.peated.com/v1"))

            await #expect(throws: URLError.self) {
                _ = try await middleware.intercept(
                    request,
                    body: nil,
                    baseURL: baseURL,
                    operationID: "createTasting"
                ) { _, _, _ in
                    throw URLError(.badServerResponse)
                }
            }

            let breadcrumb = try #require(
                recorder.breadcrumbs.first { $0.category == "http" && $0.message == "POST createTasting" }
            )
            #expect(breadcrumb.level == .error)
            #expect(breadcrumb.data["error_kind"] == .string("url.\(URLError.Code.badServerResponse.rawValue)"))
        }
    }

    @Test
    func signOutClearsTheReportedUser() async throws {
        try await withRecorder { recorder in
            let manager = try AuthenticationManager(
                apiClient: APIClient(serverURL: #require(URL(string: "https://api.peated.com/v1"))),
                deleteStoredToken: {},
                googleSignOut: {}
            )

            await manager.logout()

            #expect(recorder.userIds.last == .some(nil))
        }
    }
}
