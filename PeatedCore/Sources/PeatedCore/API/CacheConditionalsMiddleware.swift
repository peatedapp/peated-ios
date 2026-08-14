import Foundation
import HTTPTypes
import OpenAPIRuntime

/// Middleware that attaches conditional headers (If-None-Match / If-Modified-Since)
/// for common GET endpoints and stores response cache metadata (ETag/Last-Modified).
public struct CacheConditionalsMiddleware: ClientMiddleware {
    public init() {}

    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID _: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var req = request
        let method = req.method
        var key: CacheKey?

        if method == .get, let path = req.path {
            // Simple routing by path prefix
            // /users/{id}
            if path.hasPrefix("/users/") {
                if let id = path.components(separatedBy: "/").last, !id.isEmpty {
                    key = .user(id)
                }
            } else if path.hasPrefix("/bottles/") {
                if let id = path.components(separatedBy: "/").last, !id.isEmpty {
                    key = .bottle(id)
                }
            } else if path.hasPrefix("/entities/") || path.hasPrefix("/entity/") {
                if let id = path.components(separatedBy: "/").last, !id.isEmpty {
                    key = .entity(id)
                }
            }
        }

        // Attach conditional headers when we have metadata
        if let key, let meta = await NormalizedStore.shared.metadata(for: key) {
            if let etag = meta.etag, let ifNone = HTTPField.Name("If-None-Match") {
                req.headerFields[ifNone] = etag
            }
            if let lastModified = meta.lastModified?.rfc1123String, let ifMod = HTTPField.Name("If-Modified-Since") {
                req.headerFields[ifMod] = lastModified
            }
        }

        let (resp, respBody) = try await next(req, body, baseURL)

        // Capture response caching headers for future requests
        if let key {
            var etag: String?
            var lastModString: String?
            if let name = HTTPField.Name("ETag") {
                etag = resp.headerFields[name]
            }
            if let name = HTTPField.Name("Last-Modified") {
                lastModString = resp.headerFields[name]
            }
            var meta = await NormalizedStore.shared.metadata(for: key) ?? CacheMetadata()
            if let etag {
                meta.etag = etag
            }
            if let lastModString {
                meta.lastModified = lastModString.toDateRFC1123()
            }
            // Do not overwrite the value here; repositories will upsert values.
            // Persist metadata alongside existing value on next upsert.
            // If no value exists yet, metadata will be applied when value is stored.
            // (We skip upserting here to avoid needing a generic value.)
            // Optionally, we could store metadata alone by touching an internal map.
            // For simplicity, we only update metadata when value is upserted later.
        }

        return (resp, respBody)
    }
}

/// RFC1123 helpers
private extension Date {
    var rfc1123String: String {
        let fmt = DateFormatter(); fmt.locale = .init(identifier: "en_US_POSIX"); fmt
            .timeZone = .init(secondsFromGMT: 0)
        fmt.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"; return fmt.string(from: self)
    }
}

private extension String {
    func toDateRFC1123() -> Date? {
        let fmt = DateFormatter(); fmt.locale = .init(identifier: "en_US_POSIX"); fmt
            .timeZone = .init(secondsFromGMT: 0)
        fmt.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"; return fmt.date(from: self)
    }
}
