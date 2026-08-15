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

    @Test
    func cancelledSearchDoesNotExposeAnError() async {
        let repository = CollectionRepositoryStub(throwsCancellation: true)
        let model = LibraryViewModel(repository: repository)

        await model.load(query: "ardbeg")

        #expect(model.error == nil)
        #expect(!model.isLoading)
        #expect(!model.hasLoadedSuccessfully)
    }

    @Test
    func subsequentSearchKeepsLoadedContentVisible() async {
        let entry = libraryEntry()
        let repository = CollectionRepositoryStub(entries: [entry])
        let model = LibraryViewModel(repository: repository)
        await model.load()
        await repository.setDelay(nanoseconds: 1_000_000_000)

        let search = Task { await model.load(query: "ardbeg") }
        while !model.isLoading {
            await Task.yield()
        }

        #expect(!model.isInitialLoading)
        #expect(model.entries == [entry])

        search.cancel()
        await search.value
    }

    private func libraryEntry() -> LibraryEntry {
        LibraryEntry(
            id: "1",
            bottle: Bottle(
                id: "42",
                name: "Ten",
                fullName: "Ardbeg Ten",
                brand: Brand(id: "7", name: "Ardbeg"),
                isLibrary: true
            ),
            status: .open
        )
    }
}

private actor CollectionRepositoryStub: CollectionRepositoryProtocol {
    struct Request: Equatable, Sendable {
        let query: String?
        let status: LibraryBottleStatus?
    }

    private var requests: [Request] = []
    private let entries: [LibraryEntry]
    private let throwsCancellation: Bool
    private var delayNanoseconds: UInt64 = 0

    init(entries: [LibraryEntry] = [], throwsCancellation: Bool = false) {
        self.entries = entries
        self.throwsCancellation = throwsCancellation
    }

    func listLibraryEntries(
        user _: String,
        query: String?,
        status: LibraryBottleStatus?,
        limit _: Int
    ) async throws -> [LibraryEntry] {
        requests.append(Request(query: query, status: status))
        if throwsCancellation {
            throw CancellationError()
        }
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return entries
    }

    func addBottleToLibrary(bottleId _: String, user _: String) async throws {}

    func removeBottleFromLibrary(bottleId _: String, user _: String) async throws {}

    func latestRequest() -> Request? {
        requests.last
    }

    func setDelay(nanoseconds: UInt64) {
        delayNanoseconds = nanoseconds
    }
}
