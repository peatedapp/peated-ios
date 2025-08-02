import Foundation
import PeatedAPI

public protocol BottleRepositoryProtocol {
  func searchBottles(query: String, limit: Int) async throws -> [Bottle]
  func getBottle(id: String) async throws -> Bottle
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
    
    let response = try await client.bottles_list(
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
          Bottle(
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
            statedAge: apiBottle.statedAge.map { Int($0) }
          )
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
    
    let response = try await client.bottles_details(
      path: .init(bottle: bottleId)
    )
    
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        return Bottle(from: payload)
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