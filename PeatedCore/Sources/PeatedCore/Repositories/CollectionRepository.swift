import Foundation
import PeatedAPI

public struct UserCollection: Equatable, Sendable, Identifiable {
  public let id: String
  public let name: String
  public let totalBottles: Int
}

public actor CollectionRepository: BaseRepositoryProtocol {
  public let apiClient: APIClient

  public init(apiClient: APIClient? = nil) {
    self.apiClient = apiClient ?? APIClient(
      serverURL: URL(string: "https://api.peated.com/v1")!
    )
  }

  public func listUserCollections(user: String = "me", limit: Int = 50) async throws -> [UserCollection] {
    let client = await self.client
    let response = try await client.listCollections(
      path: .init(user: .init(value2: user)),
      query: .init(limit: Double(limit))
    )

    switch response {
    case .ok(let ok):
      switch ok.body {
      case .json(let payload):
        return payload.results.map { c in
          UserCollection(
            id: String(Int(c.id)),
            name: c.name,
            totalBottles: Int(c.totalBottles)
          )
        }
      }
    case .unauthorized:
      throw APIError.unauthorized
    case .undocumented(let status, _):
      throw APIError.unexpectedResponse(status)
    default:
      throw APIError.invalidResponse
    }
  }

  public func getFavoritesCollectionId(user: String = "me") async throws -> String? {
    let collections = try await listUserCollections(user: user)
    // Prefer a collection whose name contains "favorite"
    if let fav = collections.first(where: { $0.name.lowercased().contains("favorite") }) {
      return fav.id
    }
    // Fallback: if server only returns one list, use it
    return collections.first?.id
  }

  public func listBottles(in collectionId: String, user: String = "me", limit: Int = 100) async throws -> [Bottle] {
    let client = await self.client
    guard let cid = Double(collectionId) else { throw APIError.requestFailed("Invalid collection id") }

    let response = try await client.listCollectionBottles(
      path: .init(user: .init(value2: user), collection: .init(value2: cid)),
      query: .init(limit: Double(limit))
    )

    switch response {
    case .ok(let ok):
      switch ok.body {
      case .json(let payload):
        return payload.results.map { item in
          let b = item.bottle
          return Bottle(
            id: String(Int(b.id)),
            name: b.name,
            fullName: b.fullName,
            brand: Brand(
              id: String(Int(b.brand.id)),
              name: b.brand.name
            ),
            category: b.category?.value as? String,
            description: b.description,
            caskStrength: b.caskStrength ?? false,
            singleCask: b.singleCask ?? false,
            statedAge: b.statedAge.map { Int($0) },
            imageUrl: b.imageUrl,
            abv: b.abv,
            avgRating: b.avgRating ?? 0.0,
            totalRatings: Int(b.totalTastings ?? 0),
            isFavorite: b.isFavorite ?? true, // bottles in favorites collection should be favorited
            hasTasted: b.hasTasted
          )
        }
      }
    case .unauthorized:
      throw APIError.unauthorized
    case .undocumented(let status, _):
      throw APIError.unexpectedResponse(status)
    default:
      throw APIError.invalidResponse
    }
  }
}

extension CollectionRepository {
  public func addBottleToFavorites(bottleId: String, user: String = "me") async throws {
    guard let collectionId = try await getFavoritesCollectionId(user: user) else {
      throw APIError.requestFailed("Favorites collection not found")
    }
    let client = await self.client
    guard let cid = Double(collectionId), let bid = Double(bottleId) else {
      throw APIError.requestFailed("Invalid id(s)")
    }
    _ = try await client.addBottleToCollection(
      .init(
        path: .init(
          user: .init(value3: user),
          collection: Operations.addBottleToCollection.Input.Path.collectionPayload(value2: cid)
        ),
        body: .json(.init(bottle: bid))
      )
    )
  }

  public func removeBottleFromFavorites(bottleId: String, user: String = "me") async throws {
    guard let collectionId = try await getFavoritesCollectionId(user: user) else {
      throw APIError.requestFailed("Favorites collection not found")
    }
    let client = await self.client
    guard let cid = Double(collectionId), let bid = Double(bottleId) else {
      throw APIError.requestFailed("Invalid id(s)")
    }
    _ = try await client.removeBottleFromCollection(
      .init(
        path: .init(
          user: .init(value3: user),
          collection: Operations.removeBottleFromCollection.Input.Path.collectionPayload(value1: cid)
        ),
        body: .json(.init(bottle: bid))
      )
    )
  }
}
