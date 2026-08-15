@testable import Peated
import PeatedCore
import Testing

@MainActor
struct LibrarySearchTests {
    @Test
    func loadForwardsNormalizedSearchAndStatus() async {
        let repository = CollectionRepositoryStub()
        let model = LibraryViewModel(repository: repository)

        await model.load(status: .open, query: "  ardbeg  ")

        let request = await repository.latestRequest()
        #expect(request?.query == "ardbeg")
        #expect(request?.status == .open)
    }

    @Test
    func blankSearchLoadsUnfilteredQuery() async {
        let repository = CollectionRepositoryStub()
        let model = LibraryViewModel(repository: repository)

        await model.load(query: "   ")

        let request = await repository.latestRequest()
        #expect(request?.query == nil)
        #expect(request?.status == nil)
    }
}

private actor CollectionRepositoryStub: CollectionRepositoryProtocol {
    struct Request: Equatable, Sendable {
        let query: String?
        let status: LibraryBottleStatus?
    }

    private var requests: [Request] = []

    func listLibraryEntries(
        user _: String,
        query: String?,
        status: LibraryBottleStatus?,
        limit _: Int
    ) async throws -> [LibraryEntry] {
        requests.append(Request(query: query, status: status))
        return []
    }

    func addBottleToLibrary(bottleId _: String, user _: String) async throws {}

    func removeBottleFromLibrary(bottleId _: String, user _: String) async throws {}

    func latestRequest() -> Request? {
        requests.last
    }
}
