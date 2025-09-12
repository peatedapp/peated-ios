import Foundation
import PeatedAPI

public protocol EntityRepositoryProtocol: Sendable {
  func getEntity(id: String) async throws -> Entity
}

public actor EntityRepository: EntityRepositoryProtocol, BaseRepositoryProtocol {
  public let apiClient: APIClient
  
  public init(apiClient: APIClient? = nil) {
    self.apiClient = apiClient ?? APIClient(
      serverURL: URL(string: "https://api.peated.com/v1")!
    )
  }
  
  public func getEntity(id: String) async throws -> Entity {
    let client = await self.client
    
    // Convert entity ID to Double for API
    guard let entityIdDouble = Double(id) else {
      throw APIError.requestFailed("Invalid entity ID")
    }
    
    let response = try await client.getEntity(
      path: .init(entity: entityIdDouble)
    )
    
    switch response {
    case .ok(let output):
      switch output.body {
      case .json(let payload):
        // Map entity type from the _type array
        let entityType: Entity.EntityType
        if let types = payload._type, !types.isEmpty {
          // Extract string value from OpenAPIValueContainer
          if let firstType = types.first,
             let typeString = try? firstType.value as? String {
            entityType = mapEntityType(typeString)
          } else {
            entityType = .brand // Default if extraction fails
          }
        } else {
          entityType = .brand // Default fallback
        }
        
        return Entity(
          id: String(Int(payload.id)),
          name: payload.name,
          type: entityType,
          description: payload.description,
          imageUrl: nil, // TODO: Map when API provides it
          country: payload.country?.name,
          region: payload.region?.name,
          totalBottles: Int(payload.totalBottles ?? 0),
          totalTastings: Int(payload.totalTastings ?? 0)
        )
      }
      
    case .badRequest:
      throw APIError.requestFailed("Invalid entity request")
    case .unauthorized:
      throw APIError.unauthorized
    case .forbidden:
      throw APIError.requestFailed("Access forbidden")
    case .notFound:
      throw APIError.notFound
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
  
  private func mapEntityType(_ type: String) -> Entity.EntityType {
    switch type.lowercased() {
    case "brand":
      return .brand
    case "distillery":
      return .distillery
    case "bottler":
      return .bottler
    default:
      return .brand // Default fallback
    }
  }
}