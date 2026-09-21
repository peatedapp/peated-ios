import Foundation
import PeatedAPI

public protocol FeedRepositoryProtocol: Sendable {
    func getActivity(type: FeedType, cursor: String?, limit: Int) async throws -> ActivityPage
    func refreshActivity(type: FeedType) async throws -> ActivityPage
    func getBottleTastings(bottleId: String, cursor: String?, limit: Int) async throws -> FeedPage
    func getUserTastings(userId: String, cursor: String?, limit: Int) async throws -> FeedPage
}

/// One page of tastings for a bottle, entity, or member profile.
public struct FeedPage: Sendable {
    public let tastings: [TastingFeedItem]
    public let cursor: String?
    public let hasMore: Bool

    public init(tastings: [TastingFeedItem], cursor: String?, hasMore: Bool) {
        self.tastings = tastings
        self.cursor = cursor
        self.hasMore = hasMore
    }
}

public actor FeedRepository: FeedRepositoryProtocol, BaseRepositoryProtocol {
    public let apiClient: APIClient

    public init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    // MARK: - Activity

    static func makeActivityQuery(type: FeedType, cursor: String?, limit: Int) -> Operations.listActivity.Input.Query {
        switch type {
        case .friends:
            .init(filter: .friends, cursor: cursor, limit: Double(limit))
        case .global:
            // Critic reviews only join the global feed; the API ignores the flag for friends.
            .init(filter: .global, includeCriticReviews: true, cursor: cursor, limit: Double(limit))
        }
    }

    public func getActivity(type: FeedType, cursor: String?, limit: Int = 20) async throws -> ActivityPage {
        let client = await client
        let query = Self.makeActivityQuery(type: type, cursor: cursor, limit: limit)
        let response = try await client.listActivity(.init(query: query))
        let payload = try response.extractPayload()
        let mappings = payload.results.map(ActivityFeedMapping.init)
        let nextCursor = payload.rel.nextCursor

        let entries = mappings.flatMap(\.entries)
        Logger.api.info("✅ Received \(entries.count) activity entries")
        for entry in entries {
            seedStores(with: entry)
        }
        seedBottles(mappings.flatMap(\.bottles))

        return ActivityPage(entries: entries, cursor: nextCursor, hasMore: nextCursor != nil)
    }

    public func refreshActivity(type: FeedType) async throws -> ActivityPage {
        try await getActivity(type: type, cursor: nil, limit: 20)
    }

    // MARK: - Tasting lists

    public func getEntityTastings(entityId: String, cursor: String? = nil, limit: Int = 20) async throws -> FeedPage {
        guard let entityIdDouble = Double(entityId) else {
            throw APIError.requestFailed("Invalid entity ID")
        }

        var query = Operations.listTastings.Input.Query()
        query.entity = entityIdDouble
        return try await tastingPage(query: query, cursor: cursor, limit: limit)
    }

    public func getBottleTastings(bottleId: String, cursor: String?, limit: Int = 20) async throws -> FeedPage {
        guard let bottleId = Int(bottleId) else {
            throw APIError.requestFailed("Invalid bottle ID")
        }

        var query = Operations.listTastings.Input.Query()
        query.bottle = bottleId
        return try await tastingPage(query: query, cursor: cursor, limit: limit)
    }

    public func getUserTastings(userId: String, cursor: String?, limit: Int = 20) async throws -> FeedPage {
        guard let userIdDouble = Double(userId) else {
            throw APIError.requestFailed("Invalid user ID")
        }

        var query = Operations.listTastings.Input.Query()
        query.user = Operations.listTastings.Input.Query.userPayload(value1: userIdDouble)
        return try await tastingPage(query: query, cursor: cursor, limit: limit)
    }

    private func tastingPage(
        query: Operations.listTastings.Input.Query,
        cursor: String?,
        limit: Int
    ) async throws -> FeedPage {
        let client = await client
        var query = query
        query.limit = Double(limit)
        if let cursor {
            query.cursor = Double(cursor)
        }

        let response = try await client.listTastings(Operations.listTastings.Input(query: query))
        let payload = try response.extractPayload()

        let tastings = payload.results.map { item -> TastingFeedItem in
            let tasting = TastingFeedItem.from(item)
            seedStores(with: .tasting(tasting))
            return tasting
        }
        seedBottles(payload.results.map { Bottle(from: $0.bottle) })

        let nextCursor: String? = payload.rel.nextCursor.map { String(Int($0)) }

        return FeedPage(tastings: tastings, cursor: nextCursor, hasMore: nextCursor != nil)
    }

    // MARK: - Store seeding

    /// Seeds the user and tasting caches so profile and tasting screens open instantly.
    private func seedStores(with entry: ActivityFeedEntry) {
        switch entry {
        case let .tasting(tasting):
            seedUser(id: tasting.userId, username: tasting.username, pictureUrl: tasting.userAvatarUrl)
            Task {
                await SnapshotStore.appendUserRecent(userId: tasting.userId, tastingIds: [tasting.id])
                // Persist tasting into DB tasting cache for instant detail seeding
                try? await DatabaseManager.shared.cacheTasting(tasting)
            }
        case let .memberReview(review):
            seedUser(id: review.userId, username: review.username, pictureUrl: review.userAvatarUrl)
        case let .collectionAdd(add):
            seedUser(id: add.userId, username: add.username, pictureUrl: add.userAvatarUrl)
        case .criticReview:
            break
        }
    }

    private func seedBottles(_ bottles: [Bottle]) {
        Task {
            for bottle in bottles {
                await NormalizedStore.shared.upsert(.bottle(bottle.id), value: bottle)
            }
        }
    }

    private func seedUser(id: String, username: String, pictureUrl: String?) {
        Task {
            var user = User(id: id, email: "", username: username)
            user.pictureUrl = pictureUrl
            await NormalizedStore.shared.upsert(.user(id), value: user)
            await SnapshotStore.upsertUser(UserProfileSnapshot(id: id, username: username, pictureUrl: pictureUrl))
        }
    }
}
