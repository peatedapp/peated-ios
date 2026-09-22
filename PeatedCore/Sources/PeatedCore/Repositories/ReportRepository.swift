import Foundation
import PeatedAPI

public protocol ReportRepositoryProtocol {
    /// Sends a report to moderators. Repeating an open report is not an error; the server returns the open one.
    func report(_ target: ReportTarget, reason: ReportReason, comment: String?) async throws
}

public actor ReportRepository: ReportRepositoryProtocol, BaseRepositoryProtocol {
    public let apiClient: APIClient

    public init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    public func report(_ target: ReportTarget, reason: ReportReason, comment: String?) async throws {
        let client = await client
        let body = try Self.makeReportBody(target: target, reason: reason, comment: comment)
        let response = try await client.createReport(.init(body: .json(body)))

        switch response {
        case .ok:
            return
        case .badRequest:
            throw APIError.requestFailed("You can't report your own content.")
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("Your account can't send reports right now.")
        case .notFound:
            throw APIError.requestFailed("That content is no longer available.")
        case .internalServerError:
            throw APIError.serverError(500, "We couldn't send the report. Try again.")
        case let .undocumented(statusCode, _) where statusCode == 429:
            throw APIError.requestFailed("You've sent a lot of reports recently. Try again later.")
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    /// Builds the request body. Blank details are dropped so the server does not store empty text.
    static func makeReportBody(
        target: ReportTarget,
        reason: ReportReason,
        comment: String?
    ) throws -> Operations.createReport.Input.Body.jsonPayload {
        let objectType: Operations.createReport.Input.Body.jsonPayload.objectTypePayload
        let rawId: String
        switch target {
        case let .tasting(id):
            objectType = .tasting
            rawId = id
        case let .memberReview(id):
            objectType = .member_review
            rawId = id
        case let .comment(id):
            objectType = .comment
            rawId = id
        case let .user(id, _):
            objectType = .user
            rawId = id
        }
        guard let objectId = Int(rawId), objectId > 0 else {
            throw APIError.requestFailed("Invalid report target")
        }
        guard let apiReason = Operations.createReport.Input.Body.jsonPayload.reasonPayload(rawValue: reason.rawValue)
        else {
            throw APIError.requestFailed("Invalid report reason")
        }
        let details = comment?.trimmingCharacters(in: .whitespacesAndNewlines)
        return .init(
            objectType: objectType,
            objectId: objectId,
            reason: apiReason,
            comment: details.flatMap { $0.isEmpty ? nil : $0 }
        )
    }
}
