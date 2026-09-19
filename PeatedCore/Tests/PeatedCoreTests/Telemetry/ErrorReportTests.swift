import Foundation
import HTTPTypes
import OpenAPIRuntime
@testable import PeatedCore
import Testing

struct ErrorReportTests {
    @Test
    func dropsCancellation() {
        #expect(ErrorReport(error: CancellationError(), feature: "feed", operation: "load") == nil)
    }

    @Test(arguments: [
        URLError.Code.cancelled,
        .timedOut,
        .notConnectedToInternet,
        .networkConnectionLost,
        .dataNotAllowed,
        .cannotFindHost
    ])
    func dropsOfflineNetworkErrors(code: URLError.Code) {
        #expect(ErrorReport(error: URLError(code), feature: "feed", operation: "load") == nil)
    }

    @Test
    func reportsOtherNetworkErrors() throws {
        let report = try #require(
            ErrorReport(error: URLError(.secureConnectionFailed), feature: "feed", operation: "load")
        )

        #expect(report.kind == "url.\(URLError.Code.secureConnectionFailed.rawValue)")
        #expect(report.feature == "feed")
        #expect(report.operation == "load")
    }

    @Test
    func dropsExpectedAPIErrors() {
        let expected: [APIError] = [
            .unauthorized,
            .notFound,
            .requestFailed("Invalid credentials"),
            .timeout,
            .termsAcceptanceRequired,
            .networkError(URLError(.notConnectedToInternet))
        ]

        for error in expected {
            #expect(ErrorReport(error: error, feature: "feed", operation: "load") == nil)
        }
    }

    @Test
    func reportsServerErrorsWithoutServerMessage() throws {
        let report = try #require(
            ErrorReport(error: APIError.serverError(502, "upstream said: secret"), feature: "feed", operation: "load")
        )

        #expect(report.kind == "api.server_error")
        #expect(report.summary == "API server error 502")
    }

    @Test
    func describesMissingKeysByPath() throws {
        let error = DecodingError.keyNotFound(
            TestCodingKey("avgRating"),
            DecodingError.Context(
                codingPath: [TestCodingKey("results"), TestCodingKey(0), TestCodingKey("bottle")],
                debugDescription: "No value associated with key avgRating"
            )
        )

        let report = try #require(ErrorReport(error: error, feature: "feed", operation: "load"))

        #expect(report.kind == "decoding.key_not_found")
        #expect(report.summary == "Missing key 'avgRating' at results[0].bottle")
    }

    @Test
    func unwrapsClientErrorsWithoutRequestDetails() throws {
        let request = HTTPRequest(
            method: .get,
            scheme: "https",
            authority: "api.peated.com",
            path: "/v1/search?query=secret%20dram"
        )
        let clientError = ClientError(
            operationID: "listTastings",
            operationInput: "query=secret dram",
            request: request,
            requestBody: HTTPBody(Data("{\"notes\":\"private\"}".utf8)),
            baseURL: URL(string: "https://api.peated.com/v1"),
            response: HTTPResponse(status: .ok),
            responseBody: nil,
            causeDescription: "Failed to decode response body.",
            underlyingError: DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Expected date string to be ISO8601-formatted")
            )
        )

        let report = try #require(
            ErrorReport(error: APIError.decodingError(clientError), feature: "feed", operation: "load")
        )

        #expect(report.apiOperation == "listTastings")
        #expect(report.apiCause == "Failed to decode response body.")
        #expect(report.httpStatus == 200)
        #expect(report.kind == "decoding.data_corrupted")
        #expect(report.summary == "Corrupted data at <root>: Expected date string to be ISO8601-formatted")

        let everything = "\(report)"
        #expect(!everything.contains("secret"))
        #expect(!everything.contains("private"))
        #expect(!everything.contains("api.peated.com"))
    }

    @Test
    func describesPayloadFreeErrorsByCase() throws {
        let report = try #require(ErrorReport(error: AuthError.noIDToken, feature: "auth", operation: "sign_in"))

        #expect(report.kind == "PeatedCore.AuthError")
        #expect(report.summary == "PeatedCore.AuthError.noIDToken")
    }

    @Test
    func hidesAssociatedValuesOfUnknownErrors() throws {
        struct LeakyError: Error {
            let notes = "these tasting notes are private"
        }

        let report = try #require(ErrorReport(error: LeakyError(), feature: "tasting", operation: "save"))

        #expect(report.kind.hasSuffix("LeakyError"))
        #expect(!"\(report)".contains("private"))
    }
}

private struct TestCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ name: String) {
        stringValue = name
    }

    init(_ index: Int) {
        stringValue = String(index)
        intValue = index
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}
