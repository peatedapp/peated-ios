import Observation
import PeatedCore

/// Collects a reason and optional details, then sends one report.
@Observable
@MainActor
final class ReportModel {
    let target: ReportTarget
    var reason: ReportReason = .spam
    var details = ""
    private(set) var isSending = false
    private(set) var errorMessage: String?

    private let repository: any ReportRepositoryProtocol

    init(target: ReportTarget, repository: any ReportRepositoryProtocol = ReportRepository()) {
        self.target = target
        self.repository = repository
    }

    /// Sends the report. Returns true once moderators have it.
    func send() async -> Bool {
        guard !isSending else { return false }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            try await repository.report(target, reason: reason, comment: details)
            return true
        } catch {
            Telemetry.capture(error, feature: "moderation", operation: "report")
            errorMessage = error.localizedDescription
            return false
        }
    }
}
