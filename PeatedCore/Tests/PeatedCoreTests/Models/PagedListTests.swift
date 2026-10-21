@testable import PeatedCore
import Testing

@MainActor
struct PagedListTests {
    @Test
    func appendsPagesUntilTheLastOne() async {
        let pages = PageSource([
            1: ListPage(items: rows(1, 2), nextCursor: 2),
            2: ListPage(items: rows(3), nextCursor: nil)
        ])
        let list = PagedList(feature: "test", fetch: pages.fetch)

        await list.reload()
        #expect(list.items == rows(1, 2))
        #expect(list.hasMore)

        await list.loadMore()
        #expect(list.items == rows(1, 2, 3))
        #expect(!list.hasMore)

        await list.loadMore()
        #expect(await pages.requestedCursors == [1, 2])
    }

    @Test
    func loadsTheNextPageOnlyNearTheEnd() async {
        let pages = PageSource([
            1: ListPage(items: rows(1, 2, 3, 4, 5), nextCursor: 2),
            2: ListPage(items: rows(6), nextCursor: nil)
        ])
        let list = PagedList(feature: "test", fetch: pages.fetch)
        await list.reload()

        await list.loadMoreIfNeeded(after: Row(id: 1))
        #expect(await pages.requestedCursors == [1])

        await list.loadMoreIfNeeded(after: Row(id: 5))
        #expect(await pages.requestedCursors == [1, 2])
        #expect(list.items == rows(1, 2, 3, 4, 5, 6))
    }

    @Test
    func skipsRowsAPageRepeats() async {
        // A new row on the server shifts page 2 back by one.
        let pages = PageSource([
            1: ListPage(items: rows(1, 2), nextCursor: 2),
            2: ListPage(items: rows(2, 3), nextCursor: nil)
        ])
        let list = PagedList(feature: "test", fetch: pages.fetch)

        await list.reload()
        await list.loadMore()

        #expect(list.items == rows(1, 2, 3))
    }

    @Test
    func failedPageKeepsItemsAndWaitsForARetry() async {
        let pages = PageSource([
            1: ListPage(items: rows(1, 2), nextCursor: 2),
            2: ListPage(items: rows(3), nextCursor: nil)
        ], failingOnce: [2])
        let list = PagedList(feature: "test", fetch: pages.fetch)
        await list.reload()

        await list.loadMore()
        #expect(list.items == rows(1, 2))
        #expect(list.error != nil)

        await list.loadMoreIfNeeded(after: Row(id: 2))
        #expect(await pages.requestedCursors == [1, 2], "A failed page must not reload on scroll")

        await list.loadMore()
        #expect(list.items == rows(1, 2, 3))
        #expect(list.error == nil)
    }

    @Test
    func failedReloadClearsTheOldItems() async {
        let pages = PageSource([1: ListPage(items: rows(1, 2), nextCursor: 2)], failingOnce: [])
        let list = PagedList(feature: "test", fetch: pages.fetch)
        await list.reload()

        let failing = PageSource([:], failingOnce: [1])
        await list.reload(fetch: failing.fetch)

        #expect(list.items.isEmpty)
        #expect(!list.hasMore)
        #expect(list.error != nil)
    }

    @Test
    func reloadDropsAPageStillInFlight() async {
        let (gate, release) = AsyncStream<Void>.makeStream()
        let stale = PageSource([
            1: ListPage(items: rows(1), nextCursor: 2),
            2: ListPage(items: rows(2), nextCursor: nil)
        ], gatedCursor: 2, gate: gate)
        let fresh = PageSource([1: ListPage(items: rows(10), nextCursor: nil)])
        let list = PagedList(feature: "test", fetch: stale.fetch)
        await list.reload()

        let loadMore = Task { await list.loadMore() }
        while await stale.requestedCursors.count < 2 {
            await Task.yield()
        }
        await list.reload(fetch: fresh.fetch)
        release.yield()
        await loadMore.value

        #expect(list.items == rows(10))
        #expect(!list.hasMore)
        #expect(!list.isLoading)
    }

    @Test
    func cancellationIsNotAnError() async {
        let list = PagedList<Row>(feature: "test") { _ in throw CancellationError() }

        await list.reload()

        #expect(list.error == nil)
        #expect(!list.isLoading)
        #expect(!list.hasLoaded)
    }

    private func rows(_ ids: Int...) -> [Row] {
        ids.map(Row.init)
    }
}

private struct Row: Identifiable, Equatable, Sendable {
    let id: Int
}

private actor PageSource {
    struct Failure: Error {}

    private let pages: [Int: ListPage<Row>]
    private var failingOnce: Set<Int>
    private let gatedCursor: Int?
    private let gate: AsyncStream<Void>?
    private(set) var requestedCursors: [Int] = []

    init(
        _ pages: [Int: ListPage<Row>],
        failingOnce: Set<Int> = [],
        gatedCursor: Int? = nil,
        gate: AsyncStream<Void>? = nil
    ) {
        self.pages = pages
        self.failingOnce = failingOnce
        self.gatedCursor = gatedCursor
        self.gate = gate
    }

    nonisolated var fetch: PagedList<Row>.Fetch {
        { cursor in try await self.page(cursor) }
    }

    private func page(_ cursor: Int) async throws -> ListPage<Row> {
        requestedCursors.append(cursor)
        if failingOnce.remove(cursor) != nil {
            throw Failure()
        }
        if cursor == gatedCursor, let gate {
            for await _ in gate {
                break
            }
        }
        return pages[cursor] ?? ListPage(items: [], nextCursor: nil)
    }
}
