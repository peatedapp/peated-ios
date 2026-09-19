import Foundation
@testable import PeatedCore

/// Collects everything sent to `Telemetry` so tests can assert on the safe
/// projections that reach the reporter.
final class RecordingTelemetryReporter: TelemetryReporter, @unchecked Sendable {
    private let lock = NSLock()
    private var storedReports: [ErrorReport] = []
    private var storedBreadcrumbs: [TelemetryBreadcrumb] = []
    private var storedUserIds: [String?] = []
    private var storedLogs: [(level: TelemetryLogLevel, message: String)] = []

    var reports: [ErrorReport] {
        lock.withLock { storedReports }
    }

    var breadcrumbs: [TelemetryBreadcrumb] {
        lock.withLock { storedBreadcrumbs }
    }

    var userIds: [String?] {
        lock.withLock { storedUserIds }
    }

    var logs: [(level: TelemetryLogLevel, message: String)] {
        lock.withLock { storedLogs }
    }

    func report(_ report: ErrorReport) {
        lock.withLock { storedReports.append(report) }
    }

    func addBreadcrumb(_ breadcrumb: TelemetryBreadcrumb) {
        lock.withLock { storedBreadcrumbs.append(breadcrumb) }
    }

    func setUser(id: String?) {
        lock.withLock { storedUserIds.append(id) }
    }

    func startSpan(operation _: String, description _: String) -> (any TelemetrySpan)? {
        nil
    }

    func log(_ level: TelemetryLogLevel, _ message: String, attributes _: [String: TelemetryAttribute]) {
        lock.withLock { storedLogs.append((level, message)) }
    }
}
