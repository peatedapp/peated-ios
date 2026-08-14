import Foundation
@testable import PeatedCore
import Testing

private typealias TastingComment = PeatedCore.Comment

@MainActor
struct TastingDetailModelTests {
    @Test("Posting a comment updates the loaded tasting")
    func postCommentUpdatesTasting() async {
        let seed = TastingFeedItem.builder()
            .withId("42")
            .withCommentCount(0)
            .build()
        let postedComment = makeComment(id: "7", text: "Excellent bottle")
        let repository = MockTastingRepository(tasting: seed, createdComment: postedComment)
        let model = TastingDetailModel(
            tastingId: seed.id,
            seed: seed,
            tastingRepository: repository,
            isConnected: { true }
        )

        await model.loadComments()
        let didPost = await model.postComment("  Excellent bottle  ")

        #expect(didPost)
        #expect(loadedComments(from: model) == [postedComment])
        #expect(model.tasting?.comments == [postedComment])
        #expect(model.tasting?.commentCount == 1)
        let createdCommentTexts = await repository.createdCommentTexts
        #expect(createdCommentTexts == ["Excellent bottle"])
    }

    @Test("A failed comment post leaves existing comments unchanged")
    func failedPostPreservesComments() async {
        let existingComment = makeComment(id: "1", text: "Existing")
        let seed = TastingFeedItem.builder()
            .withId("42")
            .withCommentCount(1)
            .build()
        let repository = MockTastingRepository(
            tasting: seed,
            comments: [existingComment],
            createdComment: makeComment(id: "2", text: "New"),
            shouldFailCreateComment: true
        )
        let model = TastingDetailModel(
            tastingId: seed.id,
            seed: seed,
            tastingRepository: repository,
            isConnected: { true }
        )

        await model.loadComments()
        let didPost = await model.postComment("New")

        #expect(!didPost)
        #expect(loadedComments(from: model) == [existingComment])
        #expect(model.tasting?.commentCount == 1)
    }

    @Test("Deleting a comment updates the model and repository")
    func deleteCommentUpdatesTasting() async {
        let comment = makeComment(id: "9", text: "Remove me")
        let seed = TastingFeedItem.builder()
            .withId("42")
            .withCommentCount(1)
            .build()
        let repository = MockTastingRepository(
            tasting: seed,
            comments: [comment]
        )
        let model = TastingDetailModel(
            tastingId: seed.id,
            seed: seed,
            tastingRepository: repository,
            isConnected: { true }
        )

        await model.loadComments()
        await model.deleteComment(comment)

        #expect(loadedComments(from: model).isEmpty)
        #expect(model.tasting?.comments.isEmpty == true)
        #expect(model.tasting?.commentCount == 0)
        let deletedCommentIds = await repository.deletedCommentIds
        #expect(deletedCommentIds == [comment.id])
    }

    @Test("A failed comment deletion restores the optimistic update")
    func failedDeleteRestoresComment() async {
        let comment = makeComment(id: "9", text: "Keep me")
        let seed = TastingFeedItem.builder()
            .withId("42")
            .withCommentCount(1)
            .build()
        let repository = MockTastingRepository(
            tasting: seed,
            comments: [comment],
            shouldFailDeleteComment: true
        )
        let model = TastingDetailModel(
            tastingId: seed.id,
            seed: seed,
            tastingRepository: repository,
            isConnected: { true }
        )

        await model.loadComments()
        await model.deleteComment(comment)

        #expect(loadedComments(from: model) == [comment])
        #expect(model.tasting?.comments == [comment])
        #expect(model.tasting?.commentCount == 1)
    }

    @Test("Deleting a tasting uses the injected repository")
    func deleteTastingUsesRepository() async throws {
        let seed = TastingFeedItem.builder().withId("42").build()
        let repository = MockTastingRepository(tasting: seed)
        let model = TastingDetailModel(
            tastingId: seed.id,
            seed: seed,
            tastingRepository: repository,
            isConnected: { true }
        )

        try await model.deleteTasting()

        let deletedTastingIds = await repository.deletedTastingIds
        #expect(deletedTastingIds == [seed.id])
    }

    private func loadedComments(from model: TastingDetailModel) -> [TastingComment] {
        guard case let .loaded(comments) = model.commentState else { return [] }
        return comments
    }

    private func makeComment(id: String, text: String) -> TastingComment {
        TastingComment(
            id: id,
            text: text,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            userId: "5",
            username: "tester",
            userDisplayName: nil,
            userAvatarUrl: nil,
            tastingId: "42"
        )
    }
}

private actor MockTastingRepository: TastingRepositoryProtocol {
    let tasting: TastingFeedItem
    let comments: [TastingComment]
    let createdComment: TastingComment
    let shouldFailCreateComment: Bool
    let shouldFailDeleteComment: Bool

    private(set) var createdCommentTexts: [String] = []
    private(set) var deletedCommentIds: [String] = []
    private(set) var deletedTastingIds: [String] = []

    init(
        tasting: TastingFeedItem,
        comments: [TastingComment] = [],
        createdComment: TastingComment? = nil,
        shouldFailCreateComment: Bool = false,
        shouldFailDeleteComment: Bool = false
    ) {
        self.tasting = tasting
        self.comments = comments
        self.createdComment = createdComment ?? TastingComment(
            id: "created",
            text: "Created",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            userId: "5",
            username: "tester",
            userDisplayName: nil,
            userAvatarUrl: nil,
            tastingId: tasting.id
        )
        self.shouldFailCreateComment = shouldFailCreateComment
        self.shouldFailDeleteComment = shouldFailDeleteComment
    }

    func getTasting(id _: String) async throws -> TastingFeedItem {
        tasting
    }

    func createTasting(_: CreateTastingInput) async throws -> TastingFeedItem {
        tasting
    }

    func listComments(tastingId _: String) async throws -> [TastingComment] {
        comments
    }

    func createComment(tastingId _: String, text: String) async throws -> TastingComment {
        createdCommentTexts.append(text)
        if shouldFailCreateComment {
            throw MockError.requestFailed
        }
        return createdComment
    }

    func deleteComment(id: String) async throws {
        deletedCommentIds.append(id)
        if shouldFailDeleteComment {
            throw MockError.requestFailed
        }
    }

    func deleteTasting(id: String) async throws {
        deletedTastingIds.append(id)
    }

    func toggleToast(tastingId _: String) async throws -> Bool {
        true
    }

    private enum MockError: Error {
        case requestFailed
    }
}
