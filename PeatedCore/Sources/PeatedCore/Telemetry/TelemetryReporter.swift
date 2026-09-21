import Foundation

/// Destination for errors, breadcrumbs, spans, logs, and the signed-in user.
///
/// `PeatedCore` only knows this contract. The app installs a Sentry-backed
/// reporter at launch; tests and previews keep the default no-op reporter.
public protocol TelemetryReporter: Sendable {
    func report(_ report: ErrorReport)
    func addBreadcrumb(_ breadcrumb: TelemetryBreadcrumb)
    func setUser(id: String?)
    func startSpan(operation: String, description: String) -> (any TelemetrySpan)?
    func log(_ level: TelemetryLogLevel, _ message: String, attributes: [String: TelemetryAttribute])
}

/// A short, low-cardinality record of something that happened before an error.
public struct TelemetryBreadcrumb: Sendable, Equatable {
    public enum Level: String, Sendable {
        case info
        case warning
        case error
    }

    public var category: String
    public var message: String
    public var level: Level
    public var data: [String: TelemetryAttribute]

    public init(
        category: String,
        message: String,
        level: Level = .info,
        data: [String: TelemetryAttribute] = [:]
    ) {
        self.category = category
        self.message = message
        self.level = level
        self.data = data
    }
}

/// A timed unit of work reported to the tracing backend.
public protocol TelemetrySpan: Sendable {
    func setData(_ value: TelemetryAttribute, key: String)
    func finish(status: TelemetrySpanStatus)
}

public enum TelemetrySpanStatus: Sendable, Equatable {
    case ok
    case cancelled
    case invalidArgument
    case unauthenticated
    case permissionDenied
    case notFound
    case resourceExhausted
    case internalError
    case unknownError

    /// Maps an HTTP response status code to a span status.
    public init(httpStatus: Int) {
        self = switch httpStatus {
        case 100 ..< 400: .ok
        case 401: .unauthenticated
        case 403: .permissionDenied
        case 404: .notFound
        case 429: .resourceExhausted
        case 400 ..< 500: .invalidArgument
        case 500 ..< 600: .internalError
        default: .unknownError
        }
    }
}

public enum TelemetryLogLevel: String, Sendable {
    case info
    case warning
    case error
}

/// Attribute values are limited to scalars so private content cannot be
/// attached by accident.
public enum TelemetryAttribute: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}

/// Discards everything. Used until the app installs a real reporter, and in tests.
public struct NoopTelemetryReporter: TelemetryReporter {
    public init() {}

    public func report(_: ErrorReport) {}
    public func addBreadcrumb(_: TelemetryBreadcrumb) {}
    public func setUser(id _: String?) {}
    public func startSpan(operation _: String, description _: String) -> (any TelemetrySpan)? {
        nil
    }

    public func log(_: TelemetryLogLevel, _: String, attributes _: [String: TelemetryAttribute]) {}
}
