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

    @Test
    func nextPageKeepsTheSearchAndStatus() async {
        let first = libraryEntry(id: "1")
        let second = libraryEntry(id: "2")
        let repository = CollectionRepositoryStub(pages: [[first], [second]])
        let model = LibraryViewModel(repository: repository)
        await model.load(status: .open, query: "ardbeg")

        await model.list.loadMore()

        let request = await repository.latestRequest()
        #expect(request == .init(query: "ardbeg", status: .open, cursor: 2))
        #expect(model.entries == [first, second])
        #expect(!model.list.hasMore)
    }

    private func libraryEntry(id: String = "1") -> LibraryEntry {
        LibraryEntry(
            id: id,
            bottle: Bottle(
                id: "4\(id)",
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
        var cursor = 1
    }

    private var requests: [Request] = []
    private let pages: [[LibraryEntry]]
    private let throwsCancellation: Bool
    private var delayNanoseconds: UInt64 = 0

    init(entries: [LibraryEntry] = [], throwsCancellation: Bool = false) {
        self.init(pages: [entries], throwsCancellation: throwsCancellation)
    }

    init(pages: [[LibraryEntry]], throwsCancellation: Bool = false) {
        self.pages = pages
        self.throwsCancellation = throwsCancellation
    }

    func listLibraryEntries(
        user _: String,
        query: String?,
        status: LibraryBottleStatus?,
        cursor: Int,
        limit _: Int
    ) async throws -> ListPage<LibraryEntry> {
        requests.append(Request(query: query, status: status, cursor: cursor))
        if throwsCancellation {
            throw CancellationError()
        }
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        let index = cursor - 1
        return ListPage(
            items: pages.indices.contains(index) ? pages[index] : [],
            nextCursor: cursor < pages.count ? cursor + 1 : nil
        )
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
