import Foundation

/// One entry in the signed-in member's block list.
public struct BlockedUser: Identifiable, Equatable, Sendable {
    public let user: User
    public let blockedAt: Date

    public var id: String {
        user.id
    }

    public init(user: User, blockedAt: Date) {
        self.user = user
        self.blockedAt = blockedAt
    }
}

/// A page of the block list. `nextCursor` is nil on the last page.
public struct BlockedUsersPage: Equatable, Sendable {
    public let users: [BlockedUser]
    public let nextCursor: Int?

    public init(users: [BlockedUser], nextCursor: Int?) {
        self.users = users
        self.nextCursor = nextCursor
    }
}
