import Observation
import PeatedCore

/// Collects a reason and details, then sends one report.
@Observable
@MainActor
final class ReportModel {
    let target: ReportTarget
    /// Nil until the member picks one, so a report never carries a default reason.
    var reason: ReportReason?
    var details = ""
    private(set) var isSending = false
    private(set) var errorMessage: String?

    private let repository: any ReportRepositoryProtocol

    init(target: ReportTarget, repository: any ReportRepositoryProtocol = ReportRepository()) {
        self.target = target
        self.repository = repository
    }

    /// True when the chosen reason is meaningless without details.
    var needsDetails: Bool {
        reason?.requiresDetails ?? false
    }

    /// True once the report has everything moderators need.
    var canSend: Bool {
        reason != nil && (!needsDetails || !trimmedDetails.isEmpty)
    }

    private var trimmedDetails: String {
        details.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Sends the report. Returns true once moderators have it.
    func send() async -> Bool {
        guard !isSending, let reason, canSend else { return false }
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
