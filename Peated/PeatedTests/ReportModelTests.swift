@testable import Peated
import PeatedCore
import Testing

@MainActor
struct ReportModelTests {
    @Test
    func sendsTheChosenReasonAndDetailsForTheTarget() async {
        let repository = ReportRepositoryStub()
        let model = ReportModel(target: .comment(id: "88"), repository: repository)
        model.reason = .harassment
        model.details = "Keeps messaging me."

        let sent = await model.send()

        let reports = await repository.reports
        #expect(sent)
        #expect(reports.count == 1)
        #expect(reports.first?.target == .comment(id: "88"))
        #expect(reports.first?.reason == .harassment)
        #expect(reports.first?.comment == "Keeps messaging me.")
        #expect(model.errorMessage == nil)
        #expect(!model.isSending)
    }

    @Test
    func keepsTheSheetOpenWithTheErrorWhenSendingFails() async {
        let repository = ReportRepositoryStub(error: APIError.requestFailed("You can't report your own content."))
        let model = ReportModel(target: .tasting(id: "1"), repository: repository)

        let sent = await model.send()

        #expect(!sent)
        #expect(model.errorMessage == "You can't report your own content.")
        #expect(!model.isSending)
    }
}

private actor ReportRepositoryStub: ReportRepositoryProtocol {
    struct Report: Equatable {
        let target: ReportTarget
        let reason: ReportReason
        let comment: String?
    }

    private(set) var reports: [Report] = []
    private let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func report(_ target: ReportTarget, reason: ReportReason, comment: String?) async throws {
        if let error {
            throw error
        }
        reports.append(Report(target: target, reason: reason, comment: comment))
    }
}
