import Foundation
import PeatedAPI

public protocol SearchRepositoryProtocol {
    func search(query: String, limit: Int) async throws -> [SearchResult]
}

public actor SearchRepository: SearchRepositoryProtocol, BaseRepositoryProtocol {
    public let apiClient: APIClient
    private let bottleRepository: BottleRepository

    public init(apiClient: APIClient? = nil) {
        let client = apiClient ?? APIClient.shared
        self.apiClient = client
        bottleRepository = BottleRepository(apiClient: client)
    }

    public func search(query: String, limit: Int = 50) async throws -> [SearchResult] {
        async let bottlesTask = searchBottles(query: query, limit: limit)
        async let entitiesTask = searchEntities(query: query, limit: limit)
        async let usersTask = searchUsers(query: query, limit: limit)

        var results = await bottlesTask + entitiesTask + usersTask

        // Promote exact name matches to the front (case-insensitive)
        let lowerQuery = query.lowercased()
        let exact = results.filter { $0.name.lowercased() == lowerQuery }
        let others = results.filter { $0.name.lowercased() != lowerQuery }
        if !exact.isEmpty {
            results = exact + others
        }

        return results
    }

    private func searchBottles(query: String, limit: Int) async -> [SearchResult] {
        do {
            let bottles = try await bottleRepository.searchBottles(query: query, limit: limit)
            return bottles.map { bottle in
                SearchResult(
                    id: bottle.id,
                    type: .bottle,
                    name: bottle.fullName,
                    subtitle: [bottle.category, bottle.statedAge.map { "\($0) years" }].compactMap(\.self)
                        .joined(separator: " • "),
                    imageUrl: bottle.imageUrl,
                    rating: bottle.avgRating,
                    ratingCount: bottle.totalRatings,
                    bottle: bottle
                )
            }
        } catch {
            return []
        }
    }

    private func searchEntities(query: String, limit: Int) async -> [SearchResult] {
        do {
            let client = await apiClient.generatedClient
            let response = try await client.listEntities(query: .init(query: query, limit: Double(limit)))
            guard case let .ok(ok) = response,
                  case let .json(payload) = ok.body else {
                return []
            }
            return payload.results.map { entity in
                SearchResult(
                    id: String(Int(entity.id)),
                    type: .entity,
                    name: entity.name,
                    subtitle: entity.shortName
                )
            }
        } catch {
            return []
        }
    }

    private func searchUsers(query: String, limit: Int) async -> [SearchResult] {
        do {
            let client = await apiClient.generatedClient
            let response = try await client.listUsers(query: .init(query: query, limit: Double(limit)))
            guard case let .ok(ok) = response,
                  case let .json(payload) = ok.body else {
                return []
            }
            return payload.results.map { user in
                SearchResult(
                    id: String(Int(user.id)),
                    type: .user,
                    name: user.username,
                    imageUrl: user.pictureUrl,
                    friendStatus: user.friendStatus.flatMap { User.FriendStatus(rawValue: $0.rawValue) }
                )
            }
        } catch {
            return []
        }
    }
}
