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
    self.bottleRepository = BottleRepository(apiClient: client)
  }

  public func search(query: String, limit: Int = 50) async throws -> [SearchResult] {
    let client = await apiClient.generatedClient

    async let bottlesTask: [SearchResult] = {
      do {
        let bottles = try await bottleRepository.searchBottles(query: query, limit: limit)
        return bottles.map { b in
          SearchResult(
            id: b.id,
            type: .bottle,
            name: b.fullName,
            subtitle: [b.category, b.statedAge.map { "\($0) years" }].compactMap { $0 }.joined(separator: " • "),
            imageUrl: b.imageUrl,
            rating: b.avgRating,
            ratingCount: b.totalRatings,
            isFollowing: nil,
            bottle: b
          )
        }
      } catch {
        return []
      }
    }()

    async let entitiesTask: [SearchResult] = {
      do {
        let response = try await client.listEntities(
          query: .init(query: query, limit: Double(limit))
        )
        switch response {
        case .ok(let ok):
          if case .json(let payload) = ok.body {
            return payload.results.map { e in
              SearchResult(
                id: String(Int(e.id)),
                type: .entity,
                name: e.name,
                subtitle: e.shortName,
                imageUrl: nil,
                rating: nil,
                ratingCount: nil,
                isFollowing: nil
              )
            }
          }
          return []
        case .unauthorized, .forbidden:
          return []
        default:
          return []
        }
      } catch {
        return []
      }
    }()

    async let usersTask: [SearchResult] = {
      do {
        let response = try await client.listUsers(
          query: .init(query: query, limit: Double(limit))
        )
        switch response {
        case .ok(let ok):
          if case .json(let payload) = ok.body {
            return payload.results.map { u in
              SearchResult(
                id: String(Int(u.id)),
                type: .user,
                name: u.username,
                subtitle: nil,
                imageUrl: u.pictureUrl,
                rating: nil,
                ratingCount: nil,
                isFollowing: nil
              )
            }
          }
          return []
        case .unauthorized, .forbidden:
          // Endpoint requires auth; if not available, just omit users
          return []
        default:
          return []
        }
      } catch {
        return []
      }
    }()

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
}
