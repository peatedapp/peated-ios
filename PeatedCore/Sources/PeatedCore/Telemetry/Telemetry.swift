import Foundation
import os

/// Entry point for error, breadcrumb, span, and log telemetry.
///
/// The app installs a reporter once at launch. Until then, and in tests,
/// everything goes to `NoopTelemetryReporter`. Telemetry never throws and
/// never changes product behavior.
public enum Telemetry {
    private static let storage = OSAllocatedUnfairLock<any TelemetryReporter>(
        initialState: NoopTelemetryReporter()
    )

    public static var reporter: any TelemetryReporter {
        storage.withLock { $0 }
    }

    public static func install(_ reporter: any TelemetryReporter) {
        storage.withLock { $0 = reporter }
    }

    /// Captures an unexpected failure once, at the boundary that owns it.
    ///
    /// Cancellation, offline state, rejected input, and expired sessions are
    /// dropped by `ErrorReport`. Returns the report that was sent, if any.
    @discardableResult
    public static func capture(
        _ error: any Error,
        feature: String,
        operation: String,
        attributes: [String: TelemetryAttribute] = [:]
    ) -> ErrorReport? {
        guard let report = ErrorReport(
            error: error,
            feature: feature,
            operation: operation,
            attributes: attributes
        ) else {
            return nil
        }

        Logger.telemetry.error(
            """
            Captured failure
            feature=\(report.feature, privacy: .public)
            operation=\(report.operation, privacy: .public)
            kind=\(report.kind, privacy: .public)
            api=\(report.apiOperation ?? "", privacy: .public)
            summary=\(report.summary, privacy: .public)
            """
        )
        reporter.report(report)
        return report
    }

    public static func addBreadcrumb(_ breadcrumb: TelemetryBreadcrumb) {
        reporter.addBreadcrumb(breadcrumb)
    }

    /// Identifies the signed-in account by its stable id only. Pass `nil` on sign-out.
    public static func setUser(id: String?) {
        reporter.setUser(id: id)
    }

    public static func startSpan(operation: String, description: String) -> (any TelemetrySpan)? {
        reporter.startSpan(operation: operation, description: description)
    }

    public static func log(
        _ level: TelemetryLogLevel,
        _ message: String,
        attributes: [String: TelemetryAttribute] = [:]
    ) {
        reporter.log(level, message, attributes: attributes)
    }
}
