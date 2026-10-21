import Foundation
import PeatedAPI

public protocol EntityRepositoryProtocol: Sendable {
    func getEntity(id: String) async throws -> Entity
    func searchEntities(query: String, limit: Int) async throws -> [Entity]
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
                let entity = Entity(
                    id: String(Int(payload.id)),
                    name: payload.name,
                    type: mapEntityType(payload.kind.rawValue),
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

    public func searchEntities(query: String, limit: Int = 25) async throws -> [Entity] {
        let client = await client
        let response = try await client.listEntities(
            query: .init(query: query, limit: Double(limit))
        )

        switch response {
        case let .ok(output):
            switch output.body {
            case let .json(payload):
                return payload.results.map { result in
                    Entity(
                        id: String(Int(result.id)),
                        name: result.name,
                        type: mapEntityType(result.kind.rawValue),
                        description: result.description,
                        country: result.country?.name,
                        region: result.region?.name,
                        totalBottles: Int(result.totalBottles),
                        totalTastings: Int(result.totalTastings)
                    )
                }
            }
        case .badRequest:
            throw APIError.requestFailed("Invalid entity search")
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
        case "company":
            .company
        default:
            .brand // Default fallback
        }
    }
}
