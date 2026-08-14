import Foundation
import PeatedAPI

public protocol EntityRepositoryProtocol: Sendable {
    func getEntity(id: String) async throws -> Entity
}

public actor EntityRepository: EntityRepositoryProtocol, BaseRepositoryProtocol {
    public let apiClient: APIClient

    public init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    public func getEntity(id: String) async throws -> Entity {
        let client = await client

        // Convert entity ID to Double for API
        guard let entityIdDouble = Double(id) else {
            throw APIError.requestFailed("Invalid entity ID")
        }

        let response = try await client.getEntity(
            path: .init(entity: entityIdDouble)
        )

        switch response {
        case let .ok(output):
            switch output.body {
            case let .json(payload):
                // Map entity type from the _type array
                let entityType: Entity.EntityType = if let types = payload._type, !types.isEmpty {
                    if let firstType = types.first {
                        mapEntityType(firstType.rawValue)
                    } else {
                        .brand // Default if extraction fails
                    }
                } else {
                    .brand // Default fallback
                }

                let entity = Entity(
                    id: String(Int(payload.id)),
                    name: payload.name,
                    type: entityType,
                    description: payload.description,
                    imageUrl: nil, // TODO: Map when API provides it
                    country: payload.country?.name,
                    region: payload.region?.name,
                    totalBottles: Int(payload.totalBottles),
                    totalTastings: Int(payload.totalTastings)
                )
                await NormalizedStore.shared.upsert(.entity(entity.id), value: entity)
                await SnapshotStore.upsertEntity(EntitySnapshot(
                    id: entity.id,
                    name: entity.name,
                    type: entity.type,
                    imageUrl: entity.imageUrl
                ))
                return entity
            }
        case .badRequest:
            throw APIError.requestFailed("Invalid entity request")
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("Access forbidden")
        case .notFound:
            throw APIError.notFound
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    private func mapEntityType(_ type: String) -> Entity.EntityType {
        switch type.lowercased() {
        case "brand":
            .brand
        case "distillery":
            .distillery
        case "bottler":
            .bottler
        default:
            .brand // Default fallback
        }
    }
}
