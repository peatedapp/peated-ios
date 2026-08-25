import Foundation
import HTTPTypes
import OpenAPIRuntime
import PeatedAPI

/// Adapts the generated JSON representation of a bottle photo to the multipart
/// request expected by oRPC's nested Blob serializer.
struct BottlePhotoUploadMiddleware: ClientMiddleware {
    private struct Input: Decodable {
        let file: String
        let idempotencyKey: String
    }

    private static let jpegDataURLPrefix = "data:image/jpeg;base64,"
    private static let maximumEncodedBodySize = 32 * 1024 * 1024

    private let boundary: String

    init(boundary: String = "Peated-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        guard operationID == Operations.identifyTastingBottleFromPhoto.id,
              let body
        else {
            return try await next(request, body, baseURL)
        }

        let encodedBody = try await Data(
            collecting: body,
            upTo: Self.maximumEncodedBodySize
        )
        guard let input = try? JSONDecoder().decode(Input.self, from: encodedBody),
              input.file.hasPrefix(Self.jpegDataURLPrefix),
              let imageData = Data(
                  base64Encoded: String(input.file.dropFirst(Self.jpegDataURLPrefix.count))
              )
        else {
            return try await next(request, HTTPBody(encodedBody), baseURL)
        }

        let multipartBody = makeMultipartBody(
            imageData: imageData,
            idempotencyKey: input.idempotencyKey
        )

        var multipartRequest = request
        multipartRequest.headerFields[.contentType] =
            "multipart/form-data; boundary=\(boundary)"
        multipartRequest.headerFields[.contentLength] = String(multipartBody.count)

        return try await next(multipartRequest, HTTPBody(multipartBody), baseURL)
    }

    private func makeMultipartBody(imageData: Data, idempotencyKey: String) -> Data {
        var body = Data()
        body.appendUTF8("--\(boundary)\r\n")
        body.appendUTF8(
            "Content-Disposition: form-data; name=\"file\"; filename=\"bottle.jpg\"\r\n"
        )
        body.appendUTF8("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.appendUTF8("\r\n--\(boundary)\r\n")
        body.appendUTF8("Content-Disposition: form-data; name=\"idempotencyKey\"\r\n\r\n")
        body.appendUTF8(idempotencyKey)
        body.appendUTF8("\r\n--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func appendUTF8(_ value: String) {
        append(contentsOf: value.utf8)
    }
}
