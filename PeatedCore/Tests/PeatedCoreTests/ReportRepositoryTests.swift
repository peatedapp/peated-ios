@testable import PeatedAPI
@testable import PeatedCore
import Testing

struct ReportRepositoryTests {
    typealias ObjectType = Operations.createReport.Input.Body.jsonPayload.objectTypePayload

    private static let targets: [(ReportTarget, ObjectType)] = [
        (.tasting(id: "12"), .tasting),
        (.memberReview(id: "12"), .member_review),
        (.comment(id: "12"), .comment),
        (.user(id: "12", username: "sam"), .user),
        (.bottle(id: "12"), .bottle),
        (.entity(id: "12", type: .distillery), .entity)
    ]

    @Test(arguments: targets)
    func sendsTheTargetTypeAndId(target: ReportTarget, objectType: ObjectType) throws {
        let body = try ReportRepository.makeReportBody(target: target, reason: .spam, comment: nil)

        #expect(body.objectType == objectType)
        #expect(body.objectId.value1 == 12)
        #expect(body.objectId.value2 == nil)
        #expect(body.reason == .spam)
        #expect(body.comment == nil)
    }

    @Test(arguments: ReportReason.allCases)
    func sendsEveryReasonUnderTheServersName(reason: ReportReason) throws {
        let body = try ReportRepository.makeReportBody(target: .tasting(id: "1"), reason: reason, comment: nil)

        #expect(body.reason.rawValue == reason.rawValue)
    }

    @Test
    func trimsDetailsAndDropsBlankOnes() throws {
        let withDetails = try ReportRepository.makeReportBody(
            target: .comment(id: "3"),
            reason: .harassment,
            comment: "  keeps messaging me  \n"
        )
        let blank = try ReportRepository.makeReportBody(target: .comment(id: "3"), reason: .other, comment: "   ")

        #expect(withDetails.comment == "keeps messaging me")
        #expect(blank.comment == nil)
    }

    @Test
    func rejectsTargetsWithoutANumericId() {
        #expect(throws: APIError.self) {
            try ReportRepository.makeReportBody(target: .user(id: "sam", username: "sam"), reason: .spam, comment: nil)
        }
    }
}
