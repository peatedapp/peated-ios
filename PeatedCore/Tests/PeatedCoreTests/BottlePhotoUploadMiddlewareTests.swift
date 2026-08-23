import Foundation
import HTTPTypes
import OpenAPIRuntime
import PeatedAPI
@testable import PeatedCore
import Testing

struct BottlePhotoUploadMiddlewareTests {
    @Test
    func convertsBottlePhotoJSONToMultipartFormData() async throws {
        let middleware = BottlePhotoUploadMiddleware(boundary: "test-boundary")
        let request = HTTPRequest(
            method: .post,
            scheme: "https",
            authority: "api.peated.com",
            path: "/v1/tastings/photo-identification"
        )
        let encodedBody = try JSONEncoder().encode([
            "file": "data:image/jpeg;base64,AQID",
            "idempotencyKey": "photo-request"
        ])
        let capture = RequestCapture()
        let baseURL = try #require(URL(string: "https://api.peated.com/v1"))

        _ = try await middleware.intercept(
            request,
            body: HTTPBody(encodedBody),
            baseURL: baseURL,
            operationID: Operations.identifyTastingBottleFromPhoto.id
        ) { request, body, _ in
            let responseBody = try #require(body)
            let data = try await Data(collecting: responseBody, upTo: 4096)
            await capture.record(request: request, body: data)
            return (HTTPResponse(status: .ok), nil)
        }

        let captured = await capture.value()
        #expect(captured?.contentType == "multipart/form-data; boundary=test-boundary")
        let body = try #require(captured?.body)
        let bodyText = try #require(String(data: body, encoding: .utf8))
        #expect(bodyText.contains("name=\"file\"; filename=\"bottle.jpg\""))
        #expect(bodyText.contains("Content-Type: image/jpeg"))
        #expect(bodyText.contains("\u{1}\u{2}\u{3}"))
        #expect(bodyText.contains("name=\"idempotencyKey\"\r\n\r\nphoto-request"))
        #expect(bodyText.hasSuffix("--test-boundary--\r\n"))
    }

    @Test
    func leavesOtherOperationsUnchanged() async throws {
        let middleware = BottlePhotoUploadMiddleware(boundary: "test-boundary")
        let originalBody = Data("{\"value\":true}".utf8)
        let capture = RequestCapture()
        let baseURL = try #require(URL(string: "https://api.peated.com/v1"))

        _ = try await middleware.intercept(
            HTTPRequest(method: .post, path: "/other"),
            body: HTTPBody(originalBody),
            baseURL: baseURL,
            operationID: "otherOperation"
        ) { request, body, _ in
            let responseBody = try #require(body)
            let data = try await Data(collecting: responseBody, upTo: 4096)
            await capture.record(request: request, body: data)
            return (HTTPResponse(status: .ok), nil)
        }

        let captured = await capture.value()
        #expect(captured?.contentType == nil)
        #expect(captured?.body == originalBody)
    }
}

private actor RequestCapture {
    struct Value: Sendable {
        let contentType: String?
        let body: Data
    }

    private var capturedValue: Value?

    func record(request: HTTPRequest, body: Data) {
        capturedValue = Value(
            contentType: request.headerFields[.contentType],
            body: body
        )
    }

    func value() -> Value? {
        capturedValue
    }
}
