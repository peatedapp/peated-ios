import Foundation
import PeatedCore
import Sentry

/// Sends `PeatedCore` telemetry to Sentry.
///
/// Only the safe projections built in `PeatedCore` reach this type. It never
/// receives raw errors, URLs, request bodies, or user content.
struct SentryTelemetryReporter: TelemetryReporter {
    private static let dsn =
        "https://768306340a5c4721d816c33502f7e06e@o4505211758706688.ingest.us.sentry.io/4510132027457536"

    /// Starts the SDK and installs this reporter for `PeatedCore`.
    static func start(distribution: BuildDistribution = .current) {
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = distribution.sentryEnvironment
            options.debug = distribution == .development

            // Private user data is opt-in at reviewed capture sites.
            options.sendDefaultPii = false

            // Automatic HTTP instrumentation records URLs with query strings and
            // can attach request details. API spans and breadcrumbs come from
            // LoggingMiddleware with generated operation ids only.
            options.enableNetworkTracking = false
            options.enableNetworkBreadcrumbs = false
            options.enableCaptureFailedRequests = false

            // SwiftUI controls do not produce useful UIKit interaction events,
            // and swizzled control titles could contain tasting or account text.
            options.enableUserInteractionTracing = false

            // Sample 20% of transactions for performance monitoring in production
            options.tracesSampleRate = 0.2

            // Configure profiling - sample 10% of sessions
            options.configureProfiling = {
                $0.sessionSampleRate = 0.1
                $0.lifecycle = .trace
            }

            // Structured logs receive the allowlisted fields from PeatedCore.Logger.
            options.experimental.enableLogs = true

            // Screenshots, view hierarchies, and session replay can contain
            // private tasting, account, and photo data. Keep them disabled.
        }

        Telemetry.install(SentryTelemetryReporter())
    }

    // MARK: - TelemetryReporter

    func report(_ report: ErrorReport) {
        // The report kind and summary replace the original error so Sentry never
        // sees OpenAPI client descriptions, which include request bodies.
        let error = NSError(
            domain: report.kind,
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: report.summary]
        )

        SentrySDK.capture(error: error) { scope in
            scope.setTag(value: report.feature, key: "feature")
            scope.setTag(value: report.operation, key: "operation")
            scope.setTag(value: report.kind, key: "error.kind")
            if let apiOperation = report.apiOperation {
                scope.setTag(value: apiOperation, key: "api.operation")
            }
            if let httpStatus = report.httpStatus {
                scope.setTag(value: String(httpStatus), key: "http.status_code")
            }

            var context: [String: Any] = ["summary": report.summary]
            if let apiCause = report.apiCause {
                context["api_cause"] = apiCause
            }
            for (key, value) in report.attributes {
                context[key] = value.sentryValue
            }
            scope.setContext(value: context, key: "error_report")

            // One issue per failing action and error kind, regardless of the
            // async stack that led there.
            scope.setFingerprint([report.feature, report.operation, report.kind, report.apiOperation ?? ""])
        }
    }

    func addBreadcrumb(_ breadcrumb: TelemetryBreadcrumb) {
        let crumb = Breadcrumb(level: breadcrumb.level.sentryLevel, category: breadcrumb.category)
        crumb.message = breadcrumb.message
        crumb.data = breadcrumb.data.mapValues(\.sentryValue)
        SentrySDK.addBreadcrumb(crumb)
    }

    func setUser(id: String?) {
        guard let id else {
            SentrySDK.setUser(nil)
            return
        }
        // Stable identifier only. Username and email stay out of events.
        SentrySDK.setUser(Sentry.User(userId: id))
    }

    func startSpan(operation: String, description: String) -> (any TelemetrySpan)? {
        guard let parent = SentrySDK.span else { return nil }
        return SentrySpanAdapter(span: parent.startChild(operation: operation, description: description))
    }

    func log(_ level: TelemetryLogLevel, _ message: String, attributes: [String: TelemetryAttribute]) {
        let values = attributes.mapValues(\.sentryValue)
        switch level {
        case .info:
            SentrySDK.logger.info(message, attributes: values)
        case .warning:
            SentrySDK.logger.warn(message, attributes: values)
        case .error:
            SentrySDK.logger.error(message, attributes: values)
        }
    }
}

private struct SentrySpanAdapter: TelemetrySpan, @unchecked Sendable {
    let span: any Span

    func setData(_ value: TelemetryAttribute, key: String) {
        span.setData(value: value.sentryValue, key: key)
    }

    func finish(status: TelemetrySpanStatus) {
        span.finish(status: status.sentryStatus)
    }
}

private extension TelemetryAttribute {
    var sentryValue: Any {
        switch self {
        case let .string(value): value
        case let .int(value): value
        case let .double(value): value
        case let .bool(value): value
        }
    }
}

private extension TelemetryBreadcrumb.Level {
    var sentryLevel: SentryLevel {
        switch self {
        case .info: .info
        case .warning: .warning
        case .error: .error
        }
    }
}

private extension TelemetrySpanStatus {
    var sentryStatus: SentrySpanStatus {
        switch self {
        case .ok: .ok
        case .cancelled: .cancelled
        case .invalidArgument: .invalidArgument
        case .unauthenticated: .unauthenticated
        case .permissionDenied: .permissionDenied
        case .notFound: .notFound
        case .resourceExhausted: .resourceExhausted
        case .internalError: .internalError
        case .unknownError: .unknownError
        }
    }
}
