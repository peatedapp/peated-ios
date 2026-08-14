import Foundation
import PeatedAPI

public protocol FeedRepositoryProtocol: Sendable {
    func getFeed(type: FeedType, cursor: String?, limit: Int) async throws -> FeedPage
    func refreshFeed(type: FeedType) async throws -> FeedPage
    func getBottleTastings(bottleId: String, cursor: String?, limit: Int) async throws -> FeedPage
    func getUserTastings(userId: String, cursor: String?, limit: Int) async throws -> FeedPage
}

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
    private let authManager = AuthenticationManager.shared

    public init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    public func getFeed(type: FeedType, cursor: String?, limit: Int = 20) async throws -> FeedPage {
        let client = await client
        let query = try Self.makeFeedQuery(
            type: type,
            cursor: cursor,
            limit: limit,
            currentUserId: authManager.currentUser?.id
        )

        let response: Operations.listTastings.Output
        let payload: Operations.listTastings.Output.Ok.Body.jsonPayload

        do {
            response = try await client.listTastings(Operations.listTastings.Input(query: query))
            Logger.api.info("✅ Received listTastings response")

            payload = try response.extractPayload()
            Logger.api.info("✅ Extracted payload with \(payload.results.count) results")
        } catch {
            Logger.api.error("❌ FeedRepository ERROR: \(error.localizedDescription)")
            throw error
        }

        let tastings = payload.results.map { item -> TastingFeedItem in
            let t = TastingFeedItem.from(item)
            // Seed cache for referenced entities, including per-user flags
            Task {
                var u = User(id: t.userId, email: "", username: t.username)
                u.pictureUrl = t.userAvatarUrl
                await NormalizedStore.shared.upsert(.user(t.userId), value: u)
                await SnapshotStore.upsertUser(UserProfileSnapshot(
                    id: t.userId,
                    username: t.username,
                    pictureUrl: t.userAvatarUrl
                ))
                await SnapshotStore.appendUserRecent(userId: t.userId, tastingIds: [t.id])
                let b = item.bottle
                await NormalizedStore.shared.upsert(.bottle(t.bottleId), value: Bottle(
                    id: t.bottleId,
                    name: t.bottleName, // best effort; fullName expected here
                    fullName: t.bottleName,
                    brand: Brand(id: "0", name: t.bottleBrandName),
                    category: t.bottleCategory,
                    imageUrl: t.bottleImageUrl,
                    isFavorite: b.isFavorite,
                    isLibrary: b.isLibrary,
                    hasTasted: b.hasTasted
                ))
                // Persist tasting into DB tasting cache for instant detail seeding
                try? await DatabaseManager.shared.cacheTasting(t)
            }
            return t
        }

        // Use the cursor from the API response
        let nextCursor: String? = if let apiCursor = payload.rel.nextCursor {
            String(Int(apiCursor))
        } else {
            nil
        }

        // Check if there are more results based on cursor presence
        let hasMore = nextCursor != nil

        return FeedPage(
            tastings: tastings,
            cursor: nextCursor,
            hasMore: hasMore
        )
    }

    static func makeFeedQuery(
        type: FeedType,
        cursor: String?,
        limit: Int,
        currentUserId: String?
    ) throws -> Operations.listTastings.Input.Query {
        var query = Operations.listTastings.Input.Query(
            cursor: cursor.flatMap(Double.init),
            limit: Double(limit)
        )

        switch type {
        case .friends:
            query.filter = .friends
        case .personal:
            guard let currentUserId, let numericUserId = Double(currentUserId) else {
                throw APIError.requestFailed("Not authenticated")
            }
            query.user = .init(value1: numericUserId)
        case .global:
            query.filter = .global
        }

        return query
    }

    public func refreshFeed(type: FeedType) async throws -> FeedPage {
        // For refresh, we always start from the beginning
        try await getFeed(type: type, cursor: nil, limit: 20)
    }

    public func getEntityTastings(entityId: String, cursor: String? = nil, limit: Int = 20) async throws -> FeedPage {
        let client = await client

        guard let entityIdDouble = Double(entityId) else {
            throw APIError.requestFailed("Invalid entity ID")
        }

        // Create the query
        var query = Operations.listTastings.Input.Query()
        query.entity = entityIdDouble
        query.limit = Double(limit)

        if let cursor {
            query.cursor = Double(cursor)
        }

        let response = try await client.listTastings(Operations.listTastings.Input(query: query))
        let payload = try response.extractPayload()

        let tastings = payload.results.map { item -> TastingFeedItem in
            let t = TastingFeedItem.from(item)
            Task {
                var u = User(id: t.userId, email: "", username: t.username)
                u.pictureUrl = t.userAvatarUrl
                await NormalizedStore.shared.upsert(.user(t.userId), value: u)
                await SnapshotStore.upsertUser(UserProfileSnapshot(
                    id: t.userId,
                    username: t.username,
                    pictureUrl: t.userAvatarUrl
                ))
                await SnapshotStore.appendUserRecent(userId: t.userId, tastingIds: [t.id])
                let b = item.bottle
                await NormalizedStore.shared.upsert(.bottle(t.bottleId), value: Bottle(
                    id: t.bottleId,
                    name: t.bottleName,
                    fullName: t.bottleName,
                    brand: Brand(id: "0", name: t.bottleBrandName),
                    category: t.bottleCategory,
                    imageUrl: t.bottleImageUrl,
                    isFavorite: b.isFavorite,
                    isLibrary: b.isLibrary,
                    hasTasted: b.hasTasted
                ))
                try? await DatabaseManager.shared.cacheTasting(t)
            }
            return t
        }

        // Use the cursor from the API response
        let nextCursor: String? = if let apiCursor = payload.rel.nextCursor {
            String(Int(apiCursor))
        } else {
            nil
        }

        // Check if there are more results based on cursor presence
        let hasMore = nextCursor != nil

        return FeedPage(
            tastings: tastings,
            cursor: nextCursor,
            hasMore: hasMore
        )
    }

    public func getBottleTastings(bottleId: String, cursor: String?, limit: Int = 20) async throws -> FeedPage {
        let client = await client

        guard let bottleId = Int(bottleId) else {
            throw APIError.requestFailed("Invalid bottle ID")
        }

        // Build the query parameters
        var query = Operations.listTastings.Input.Query()
        query.bottle = bottleId
        query.limit = Double(limit)

        if let cursor {
            query.cursor = Double(cursor)
        }

        let response = try await client.listTastings(Operations.listTastings.Input(query: query))
        let payload = try response.extractPayload()

        let tastings = payload.results.map { item -> TastingFeedItem in
            let t = TastingFeedItem.from(item)
            Task {
                var u = User(id: t.userId, email: "", username: t.username)
                u.pictureUrl = t.userAvatarUrl
                await NormalizedStore.shared.upsert(.user(t.userId), value: u)
                await SnapshotStore.upsertUser(UserProfileSnapshot(
                    id: t.userId,
                    username: t.username,
                    pictureUrl: t.userAvatarUrl
                ))
                await SnapshotStore.appendUserRecent(userId: t.userId, tastingIds: [t.id])
                let b = item.bottle
                await NormalizedStore.shared.upsert(.bottle(t.bottleId), value: Bottle(
                    id: t.bottleId,
                    name: t.bottleName,
                    fullName: t.bottleName,
                    brand: Brand(id: "0", name: t.bottleBrandName),
                    category: t.bottleCategory,
                    imageUrl: t.bottleImageUrl,
                    isFavorite: b.isFavorite,
                    isLibrary: b.isLibrary,
                    hasTasted: b.hasTasted
                ))
                try? await DatabaseManager.shared.cacheTasting(t)
            }
            return t
        }

        // Use the cursor from the API response
        let nextCursor: String? = if let apiCursor = payload.rel.nextCursor {
            String(Int(apiCursor))
        } else {
            nil
        }

        // Check if there are more results based on cursor presence
        let hasMore = nextCursor != nil

        return FeedPage(
            tastings: tastings,
            cursor: nextCursor,
            hasMore: hasMore
        )
    }

    public func getUserTastings(userId: String, cursor: String?, limit: Int = 20) async throws -> FeedPage {
        let client = await client

        guard let userIdDouble = Double(userId) else {
            throw APIError.requestFailed("Invalid user ID")
        }

        // Build the query parameters
        var query = Operations.listTastings.Input.Query()
        query.user = Operations.listTastings.Input.Query.userPayload(value1: userIdDouble)
        query.limit = Double(limit)

        if let cursor {
            query.cursor = Double(cursor)
        }

        let response = try await client.listTastings(Operations.listTastings.Input(query: query))
        let payload = try response.extractPayload()

        let tastings = payload.results.map { item -> TastingFeedItem in
            let t = TastingFeedItem.from(item)
            Task {
                var u = User(id: t.userId, email: "", username: t.username)
                u.pictureUrl = t.userAvatarUrl
                await NormalizedStore.shared.upsert(.user(t.userId), value: u)
                await SnapshotStore.upsertUser(UserProfileSnapshot(
                    id: t.userId,
                    username: t.username,
                    pictureUrl: t.userAvatarUrl
                ))
                await SnapshotStore.appendUserRecent(userId: t.userId, tastingIds: [t.id])
                let b = item.bottle
                await NormalizedStore.shared.upsert(.bottle(t.bottleId), value: Bottle(
                    id: t.bottleId,
                    name: t.bottleName,
                    fullName: t.bottleName,
                    brand: Brand(id: "0", name: t.bottleBrandName),
                    category: t.bottleCategory,
                    imageUrl: t.bottleImageUrl,
                    isFavorite: b.isFavorite,
                    isLibrary: b.isLibrary,
                    hasTasted: b.hasTasted
                ))
                try? await DatabaseManager.shared.cacheTasting(t)
            }
            return t
        }

        // Use the cursor from the API response
        let nextCursor: String? = if let apiCursor = payload.rel.nextCursor {
            String(Int(apiCursor))
        } else {
            nil
        }

        // Check if there are more results based on cursor presence
        let hasMore = nextCursor != nil

        return FeedPage(
            tastings: tastings,
            cursor: nextCursor,
            hasMore: hasMore
        )
    }
}
