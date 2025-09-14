import Foundation
import PeatedAPI

public protocol BottleRepositoryProtocol {
  func searchBottles(query: String, limit: Int) async throws -> [Bottle]
  func getBottle(id: String) async throws -> Bottle
  func getPopularBottles(limit: Int) async throws -> [Bottle]
  func getTopRatedBottles(limit: Int) async throws -> [Bottle]
  func getEntityBottles(entityId: String) async throws -> [Bottle]
  // TODO: Add when API endpoint is available
  // func getBottleSuggestions(prefix: String) async throws -> [Bottle]
}

public actor BottleRepository: BottleRepositoryProtocol, BaseRepositoryProtocol {
  public let apiClient: APIClient
  
  public init(apiClient: APIClient? = nil) {
    self.apiClient = apiClient ?? APIClient(
      serverURL: URL(string: "https://api.peated.com/v1")!
    )
  }
  
  public func searchBottles(query: String, limit: Int = 20) async throws -> [Bottle] {
    let client = await self.client
    
    let response = try await client.listBottles(
      query: .init(
        query: query,
        limit: Double(limit)
      )
    )
    
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        return payload.results.map { apiBottle in
          let bottle = Bottle(
            id: String(Int(apiBottle.id)),
            name: apiBottle.name,
            fullName: apiBottle.fullName,
            brand: Brand(
              id: String(Int(apiBottle.brand.id)),
              name: apiBottle.brand.name
            ),
            category: apiBottle.category?.value as? String,
            caskStrength: apiBottle.caskStrength ?? false,
            singleCask: apiBottle.singleCask ?? false,
            statedAge: apiBottle.statedAge.map { Int($0) },
            imageUrl: apiBottle.imageUrl,
            abv: apiBottle.abv,
            avgRating: 0.0,  // Not available in list endpoint
            totalRatings: 0   // Not available in list endpoint
          )
          Task { await NormalizedStore.shared.upsert(.bottle(bottle.id), value: bottle) }
          return bottle
        }
      }
    case .badRequest:
      throw APIError.requestFailed("Invalid search query")
    case .unauthorized:
      throw APIError.unauthorized
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
  
  public func getBottle(id: String) async throws -> Bottle {
    let client = await self.client
    
    guard let bottleId = Double(id) else {
      throw APIError.requestFailed("Invalid bottle ID")
    }
    
    let response = try await client.getBottle(
      path: .init(bottle: bottleId)
    )
    
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        let bottle = Bottle(from: payload)
        await NormalizedStore.shared.upsert(.bottle(bottle.id), value: bottle)
        return bottle
      }
    case .unauthorized:
      throw APIError.unauthorized
    case .notFound:
      throw APIError.notFound
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
  
  public func getPopularBottles(limit: Int = 10) async throws -> [Bottle] {
    let client = await self.client
    
    // Fetch bottles sorted by total tastings (most popular)
    let response = try await client.listBottles(
      query: .init(
        limit: Double(limit),
        sort: "tastings"
      )
    )
    
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        return payload.results.map { apiBottle in
          let bottleId = String(Int(apiBottle.id))
          let brandId = String(Int(apiBottle.brand.id))
          let brand = Brand(id: brandId, name: apiBottle.brand.name)
          let category = apiBottle.category?.value as? String
          let statedAge = apiBottle.statedAge.map { Int($0) }
          let avgRating = apiBottle.avgRating ?? 0.0
          let totalRatings = Int(apiBottle.totalTastings ?? 0)
          
          let bottle = Bottle(
            id: bottleId,
            name: apiBottle.name,
            fullName: apiBottle.fullName,
            brand: brand,
            category: category,
            caskStrength: apiBottle.caskStrength ?? false,
            singleCask: apiBottle.singleCask ?? false,
            statedAge: statedAge,
            imageUrl: apiBottle.imageUrl,
            abv: apiBottle.abv,
            avgRating: avgRating,
            totalRatings: totalRatings
          )
          Task { await NormalizedStore.shared.upsert(.bottle(bottle.id), value: bottle) }
          return bottle
        }
      }
    case .badRequest:
      throw APIError.requestFailed("Failed to fetch popular bottles")
    case .unauthorized:
      throw APIError.unauthorized
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
  
  public func getTopRatedBottles(limit: Int = 10) async throws -> [Bottle] {
    let client = await self.client
    
    // Fetch bottles sorted by rating (highest rated)
    let response = try await client.listBottles(
      query: .init(
        limit: Double(limit),
        sort: "rating"
      )
    )
    
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        return payload.results.map { apiBottle in
          let bottleId = String(Int(apiBottle.id))
          let brandId = String(Int(apiBottle.brand.id))
          let brand = Brand(id: brandId, name: apiBottle.brand.name)
          let category = apiBottle.category?.value as? String
          let statedAge = apiBottle.statedAge.map { Int($0) }
          let avgRating = apiBottle.avgRating ?? 0.0
          let totalRatings = Int(apiBottle.totalTastings ?? 0)
          
          return Bottle(
            id: bottleId,
            name: apiBottle.name,
            fullName: apiBottle.fullName,
            brand: brand,
            category: category,
            caskStrength: apiBottle.caskStrength ?? false,
            singleCask: apiBottle.singleCask ?? false,
            statedAge: statedAge,
            imageUrl: apiBottle.imageUrl,
            abv: apiBottle.abv,
            avgRating: avgRating,
            totalRatings: totalRatings
          )
        }
      }
    case .badRequest:
      throw APIError.requestFailed("Failed to fetch top rated bottles")
    case .unauthorized:
      throw APIError.unauthorized
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
  
  public func getEntityBottles(entityId: String) async throws -> [Bottle] {
    let client = await self.client
    
    guard let entityIdDouble = Double(entityId) else {
      throw APIError.requestFailed("Invalid entity ID")
    }
    
    // Fetch bottles for this entity (brand or distillery)
    let response = try await client.listBottles(
      query: .init(
        entity: entityIdDouble,
        limit: 50
      )
    )
    
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        return payload.results.map { apiBottle in
          let bottle = Bottle(
            id: String(Int(apiBottle.id)),
            name: apiBottle.name,
            fullName: apiBottle.fullName,
            brand: Brand(
              id: String(Int(apiBottle.brand.id)),
              name: apiBottle.brand.name
            ),
            category: apiBottle.category?.value as? String,
            caskStrength: apiBottle.caskStrength ?? false,
            singleCask: apiBottle.singleCask ?? false,
            statedAge: apiBottle.statedAge.map { Int($0) },
            imageUrl: apiBottle.imageUrl,
            abv: apiBottle.abv,
            avgRating: apiBottle.avgRating ?? 0.0,
            totalRatings: Int(apiBottle.totalTastings ?? 0)
          )
          Task { await NormalizedStore.shared.upsert(.bottle(bottle.id), value: bottle) }
          return bottle
        }
      }
    case .badRequest:
      throw APIError.requestFailed("Failed to fetch entity bottles")
    case .unauthorized:
      throw APIError.unauthorized
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
  
  // TODO: Implement when API endpoint is available
  // public func getBottleSuggestions(prefix: String) async throws -> [Bottle] {
  //   let client = await self.client
  //   
  //   let response = try await client.bottles_suggestions(
  //     query: .init(prefix: prefix)
  //   )
  //   
  //   switch response {
  //   case .ok(let okResponse):
  //     switch okResponse.body {
  //     case .json(let payload):
  //       return payload.results.map { suggestion in
  //         Bottle(
  //           id: String(Int(suggestion.id)),
  //           name: suggestion.name,
  //           fullName: suggestion.fullName,
  //           brand: Brand(
  //             id: String(Int(suggestion.brand.id)),
  //             name: suggestion.brand.name
  //           ),
  //           category: suggestion.category,
  //           caskStrength: false,
  //           singleCask: false,
  //           statedAge: nil
  //         )
  //       }
  //     }
  //   case .badRequest:
  //     throw APIError.requestFailed("Invalid prefix")
  //   case .unauthorized:
  //     throw APIError.unauthorized
  //   case .undocumented(let statusCode, _):
  //     throw APIError.unexpectedResponse(statusCode)
  //   default:
  //     throw APIError.invalidResponse
  //   }
  // }
}
