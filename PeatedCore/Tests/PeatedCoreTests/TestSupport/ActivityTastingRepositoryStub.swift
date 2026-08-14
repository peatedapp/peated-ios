import Foundation
@testable import PeatedCore

actor ActivityTastingRepositoryStub: TastingRepositoryProtocol {
    let toggleResult: Bool
    let shouldFailToggle: Bool

    private(set) var toggledTastingIds: [String] = []

    init(toggleResult: Bool, shouldFailToggle: Bool = false) {
        self.toggleResult = toggleResult
        self.shouldFailToggle = shouldFailToggle
    }

    func getTasting(id _: String) async throws -> TastingFeedItem {
        throw StubError.notImplemented
    }

    func createTasting(_: CreateTastingInput) async throws -> TastingFeedItem {
        throw StubError.notImplemented
    }

    func listComments(tastingId _: String) async throws -> [Comment] {
        throw StubError.notImplemented
    }

    func createComment(tastingId _: String, text _: String) async throws -> Comment {
        throw StubError.notImplemented
    }

    func deleteComment(id _: String) async throws {
        throw StubError.notImplemented
    }

    func deleteTasting(id _: String) async throws {
        throw StubError.notImplemented
    }

    func toggleToast(tastingId: String) async throws -> Bool {
        toggledTastingIds.append(tastingId)
        if shouldFailToggle {
            throw StubError.requestFailed
        }
        return toggleResult
    }

    private enum StubError: Error {
        case notImplemented
        case requestFailed
    }
}
