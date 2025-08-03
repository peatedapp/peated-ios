import Foundation
import PeatedAPI

public protocol TastingRepositoryProtocol {
  func getTasting(id: String) async throws -> TastingFeedItem
  func createTasting(_ input: CreateTastingInput) async throws -> TastingFeedItem
  func deleteTasting(id: String) async throws
  func toggleToast(tastingId: String) async throws -> Bool
}

public struct CreateTastingInput: Sendable {
  public let bottleId: String
  public let rating: Double
  public let notes: String?
  public let servingStyle: String?
  public let tags: [String]
  public let location: String?
  
  public init(
    bottleId: String,
    rating: Double,
    notes: String? = nil,
    servingStyle: String? = nil,
    tags: [String] = [],
    location: String? = nil
  ) {
    self.bottleId = bottleId
    self.rating = rating
    self.notes = notes
    self.servingStyle = servingStyle
    self.tags = tags
    self.location = location
  }
}

public actor TastingRepository: TastingRepositoryProtocol, BaseRepositoryProtocol {
  public let apiClient: APIClient
  
  public init(apiClient: APIClient? = nil) {
    self.apiClient = apiClient ?? APIClient(
      serverURL: URL(string: "https://api.peated.com/v1")!
    )
  }
  
  public func getTasting(id: String) async throws -> TastingFeedItem {
    let client = await self.client
    
    // Convert string ID to double
    guard let tastingId = Double(id) else {
      throw APIError.requestFailed("Invalid tasting ID")
    }
    
    let response = try await client.getTasting(
      path: .init(tasting: tastingId)
    )
    
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        // Map to TastingFeedItem
        return TastingFeedItem(
          id: String(Int(payload.id)),
          rating: payload.rating ?? 0.0,
          notes: payload.notes,
          servingStyle: payload.servingStyle?.value as? String,
          imageUrl: payload.imageUrl,
          createdAt: payload.createdAt,
          userId: String(Int(payload.createdBy.id)),
          username: payload.createdBy.username,
          userDisplayName: nil,
          userAvatarUrl: payload.createdBy.pictureUrl,
          bottleId: String(Int(payload.bottle.id)),
          bottleName: payload.bottle.fullName,
          bottleBrandName: payload.bottle.brand.name,
          bottleCategory: payload.bottle.category?.value as? String,
          bottleImageUrl: payload.bottle.imageUrl,
          toastCount: Int(payload.toasts),
          commentCount: Int(payload.comments),
          hasToasted: payload.hasToasted ?? false,
          tags: payload.tags ?? [],
          location: nil,
          friendUsernames: payload.friends?.map { $0.username } ?? []
        )
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
  
  public func createTasting(_ input: CreateTastingInput) async throws -> TastingFeedItem {
    let client = await self.client
    
    // Convert string bottleId to double
    guard let bottleId = Double(input.bottleId) else {
      throw APIError.requestFailed("Invalid bottle ID")
    }
    
    // Build the request body
    let body = Operations.createTasting.Input.Body.json(
      .init(
        notes: input.notes,
        bottle: bottleId,
        rating: input.rating,
        tags: input.tags.isEmpty ? nil : input.tags,
        servingStyle: input.servingStyle.flatMap { style in
          switch style {
          case "neat": return OpenAPIRuntime.OpenAPIValueContainer("neat")
          case "rocks": return OpenAPIRuntime.OpenAPIValueContainer("rocks")
          case "water": return OpenAPIRuntime.OpenAPIValueContainer("water")
          default: return nil
          }
        }
      )
    )
    
    let response = try await client.createTasting(body: body)
    
    switch response {
    case .ok(let createdResponse):
      switch createdResponse.body {
      case .json(let payload):
        // Extract the tasting from the response payload
        let tasting = payload.tasting
        let apiUser = tasting.createdBy
        let apiBottle = tasting.bottle
        
        return TastingFeedItem(
          id: String(Int(tasting.id)),
          rating: tasting.rating ?? 0.0,
          notes: tasting.notes,
          servingStyle: tasting.servingStyle?.value as? String,
          imageUrl: tasting.imageUrl,
          createdAt: tasting.createdAt,
          userId: String(Int(apiUser.id)),
          username: apiUser.username,
          userDisplayName: nil,
          userAvatarUrl: apiUser.pictureUrl,
          bottleId: String(Int(apiBottle.id)),
          bottleName: apiBottle.fullName,
          bottleBrandName: apiBottle.brand.name,
          bottleCategory: apiBottle.category?.value as? String,
          bottleImageUrl: apiBottle.imageUrl,
          toastCount: Int(tasting.toasts),
          commentCount: Int(tasting.comments),
          hasToasted: tasting.hasToasted ?? false,
          tags: tasting.tags ?? [],
          location: nil,
          friendUsernames: tasting.friends?.map { $0.username } ?? []
        )
      }
    case .badRequest:
      throw APIError.requestFailed("Invalid tasting data")
    case .unauthorized:
      throw APIError.unauthorized
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
  
  public func deleteTasting(id: String) async throws {
    let client = await self.client
    
    guard let tastingId = Double(id) else {
      throw APIError.requestFailed("Invalid tasting ID")
    }
    
    let response = try await client.deleteTasting(
      path: .init(tasting: tastingId)
    )
    
    switch response {
    case .ok:
      return
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
  
  public func toggleToast(tastingId: String) async throws -> Bool {
    let client = await self.client
    
    guard let id = Double(tastingId) else {
      throw APIError.requestFailed("Invalid tasting ID")
    }
    
    // First, check if already toasted
    let detailsResponse = try await client.getTasting(
      path: .init(tasting: id)
    )
    
    guard case .ok(let okResponse) = detailsResponse,
          case .json(let payload) = okResponse.body else {
      throw APIError.invalidResponse
    }
    
    let isCurrentlyToasted = payload.hasToasted ?? false
    
    if isCurrentlyToasted {
      // Toast delete doesn't exist in API yet
      // For now, just return false to indicate untoasted
      return false
    } else {
      // Add toast
      let response = try await client.createToast(
        .init(path: .init(tasting: id))
      )
      
      switch response {
      case .ok:
        return true
      case .unauthorized:
        throw APIError.unauthorized
      case .badRequest:
        throw APIError.requestFailed("Cannot toast this tasting")
      default:
        throw APIError.invalidResponse
      }
    }
  }
}