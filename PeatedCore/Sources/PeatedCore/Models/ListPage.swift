import Foundation

/// One page from a Peated list endpoint.
///
/// Peated list endpoints use page-number cursors. The first page is cursor 1,
/// and `nextCursor` is nil on the last page.
public struct ListPage<Item: Sendable>: Sendable {
    public static var firstCursor: Int {
        1
    }

    public let items: [Item]
    public let nextCursor: Int?

    public init(items: [Item], nextCursor: Int?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}
