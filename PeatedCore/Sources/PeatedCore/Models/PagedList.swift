import Foundation
import Observation

/// The loaded items and next cursor for one cursor-paginated list.
///
/// `reload` replaces the items with the first page. `loadMore` appends the next
/// page. Only the newest load may write results: a reload drops any page that is
/// still in flight, so a slow response for an old filter never lands on a new one.
///
/// A failed reload clears the items, so screens show their error state instead of
/// rows from an old filter. A failed later page keeps the rows already loaded.
@Observable
@MainActor
public final class PagedList<Item: Identifiable & Sendable> {
    public typealias Fetch = @Sendable (_ cursor: Int) async throws -> ListPage<Item>

    public private(set) var items: [Item]
    public private(set) var isLoading = false
    /// True once any page has loaded, so screens can tell a first load from a refresh.
    public private(set) var hasLoaded = false
    /// The latest failure. With items, it was a later page and `loadMore` retries it.
    /// A failed page stops automatic loading until then.
    public private(set) var error: (any Error)?

    public var hasMore: Bool {
        nextCursor != nil
    }

    /// How close to the end a row must be before it starts the next page.
    private static var prefetchDistance: Int {
        3
    }

    private let feature: String
    private var fetch: Fetch
    private var nextCursor: Int?
    private var generation = 0

    /// - Parameter feature: The telemetry feature that owns this list.
    public init(feature: String, items: [Item] = [], fetch: @escaping Fetch) {
        self.feature = feature
        self.items = items
        self.fetch = fetch
    }

    /// A list whose page source is not known yet, such as one that depends on a
    /// filter or on a user that is still loading. It stays empty until `reload(fetch:)`.
    public convenience init(feature: String) {
        self.init(feature: feature) { _ in ListPage(items: [], nextCursor: nil) }
    }

    /// Replaces the items with the first page. Existing items stay visible until it arrives.
    /// - Parameter newFetch: Replaces the page source, for example when a filter changes.
    public func reload(fetch newFetch: Fetch? = nil) async {
        if let newFetch {
            fetch = newFetch
        }
        await load(cursor: ListPage<Item>.firstCursor, replacing: true)
    }

    /// Loads the next page when `item` is one of the last few rows.
    public func loadMoreIfNeeded(after item: Item) async {
        guard error == nil,
              let index = items.lastIndex(where: { $0.id == item.id }),
              index >= items.count - Self.prefetchDistance
        else { return }
        await loadMore()
    }

    /// Loads the next page. This also retries a failed page.
    public func loadMore() async {
        guard let nextCursor, !isLoading else { return }
        await load(cursor: nextCursor, replacing: false)
    }

    /// Rewrites one loaded item in place, for example after an optimistic toast.
    public func update(id: Item.ID, _ transform: (Item) -> Item) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index] = transform(items[index])
    }

    private func load(cursor: Int, replacing: Bool) async {
        generation += 1
        let generation = generation
        isLoading = true
        error = nil
        defer {
            if generation == self.generation {
                isLoading = false
            }
        }

        do {
            let page = try await fetch(cursor)
            guard !Task.isCancelled, generation == self.generation else { return }
            if replacing {
                items = page.items
            } else {
                append(page.items)
            }
            nextCursor = page.nextCursor
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, generation == self.generation else { return }
            Telemetry.capture(error, feature: feature, operation: replacing ? "load" : "load_more")
            self.error = error
            if replacing {
                items = []
                nextCursor = nil
            }
        }
    }

    /// Page-number cursors shift when rows are added between requests, so a page
    /// can repeat rows the list already has. SwiftUI requires unique IDs.
    private func append(_ newItems: [Item]) {
        var seen = Set(items.map(\.id))
        items.append(contentsOf: newItems.filter { seen.insert($0.id).inserted })
    }
}
