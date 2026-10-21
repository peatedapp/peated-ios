@testable import PeatedCore
import Testing

struct TastingRepositoryCommentsTests {
    @Test
    func loadsEveryCommentPage() async throws {
        let transport = StubAPITransport([
            "listComments": [
                .json(200, Self.page(ids: [1, 2], nextCursor: "2")),
                .json(200, Self.page(ids: [3], nextCursor: "null"))
            ]
        ])
        let repository = TastingRepository(apiClient: APIClient(transport: transport))

        let comments = try await repository.listComments(tastingId: "42")

        #expect(comments.map(\.id) == ["1", "2", "3"])
    }

    private static func page(ids: [Int], nextCursor: String) -> String {
        let results = ids.map { id in
            #"""
            {"id":\#(id),"comment":"Comment \#(id)","createdAt":"2026-01-01T00:00:00.000Z",
            "createdBy":{"id":5,"username":"tester"}}
            """#
        }
        let rel = #"{"nextCursor":\#(nextCursor),"prevCursor":null}"#
        return #"{"results":[\#(results.joined(separator: ","))],"rel":\#(rel)}"#
    }
}
