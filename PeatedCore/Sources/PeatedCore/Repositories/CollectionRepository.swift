import Foundation
import PeatedAPI

public protocol CollectionRepositoryProtocol: Sendable {
    func listLibraryEntries(
        user: String,
        query: String?,
        status: LibraryBottleStatus?,
        limit: Int
    ) async throws -> [LibraryEntry]

    func addBottleToLibrary(bottleId: String, user: String) async throws
    func removeBottleFromLibrary(bottleId: String, user: String) async throws
}

public actor CollectionRepository: BaseRepositoryProtocol, CollectionRepositoryProtocol {
    public let apiClient: APIClient

    public init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    public func listLibraryEntries(
        user: String = "me",
        query: String? = nil,
        status: LibraryBottleStatus? = nil,
        limit: Int = 100
    ) async throws -> [LibraryEntry] {
        let client = await client
        let response = try await client.listCollectionBottles(
            path: .init(
                user: .init(value2: user),
                collection: .init(value1: .library)
            ),
            query: .init(
                query: query,
                status: status.map(Self.listStatusPayload),
                limit: Double(limit)
            )
        )

        switch response {
        case let .ok(ok):
            switch ok.body {
            case let .json(payload):
                return payload.results.map(Self.mapLibraryEntry)
            }
        case .badRequest:
            throw APIError.requestFailed("Invalid library request")
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("Library is private")
        case .notFound:
            throw APIError.notFound
        case .conflict:
            throw APIError.requestFailed("Library request conflicted with its current state")
        case .contentTooLarge:
            throw APIError.requestFailed("Library request was too large")
        case .internalServerError:
            throw APIError.serverError(500, "Unable to load library")
        case let .undocumented(status, _):
            throw APIError.unexpectedResponse(status)
        }
    }

    public func addBottleToLibrary(bottleId: String, user: String = "me") async throws {
        let client = await client
        guard let bottleId = Int(bottleId) else {
            throw APIError.requestFailed("Invalid bottle id")
        }

        let response = try await client.addBottleToCollection(
            .init(
                path: .init(
                    user: .init(value3: user),
                    collection: .init(value1: .library)
                ),
                body: .json(.init(bottle: bottleId))
            )
        )

        try Self.validateMutationResponse(response)
    }

    public func removeBottleFromLibrary(bottleId: String, user: String = "me") async throws {
        let client = await client
        guard let bottleId = Int(bottleId) else {
            throw APIError.requestFailed("Invalid bottle id")
        }

        let response = try await client.removeBottleFromCollection(
            .init(
                path: .init(
                    user: .init(value3: user),
                    collection: .init(value1: .library)
                ),
                body: .json(.init(bottle: bottleId))
            )
        )

        try Self.validateMutationResponse(response)
    }

    private static func listStatusPayload(
        _ status: LibraryBottleStatus
    ) -> Operations.listCollectionBottles.Input.Query.statusPayload {
        let value: Operations.listCollectionBottles.Input.Query.statusPayload.Value1Payload = switch status {
        case .sealed: .sealed
        case .open: .open
        case .empty: .empty
        }
        return .init(value1: value)
    }

    private static func mapLibraryEntry(_ item: Components.Schemas.CollectionBottle) -> LibraryEntry {
        LibraryEntry(
            id: String(Int(item.id)),
            bottle: Bottle(from: item.bottle, imageUrl: item.imageUrl, hasTasted: item.hasTasted),
            imageUrl: item.imageUrl,
            status: item.status.flatMap { LibraryBottleStatus(rawValue: $0.rawValue) }
        )
    }

    private static func validateMutationResponse(_ response: Operations.addBottleToCollection.Output) throws {
        switch response {
        case .ok:
            return
        case .badRequest:
            throw APIError.requestFailed("Invalid library request")
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("Library cannot be changed")
        case .notFound:
            throw APIError.notFound
        case .conflict:
            throw APIError.requestFailed("Bottle is already in the library")
        case .contentTooLarge:
            throw APIError.requestFailed("Library request was too large")
        case .internalServerError:
            throw APIError.serverError(500, "Unable to update library")
        case let .undocumented(status, _):
            throw APIError.unexpectedResponse(status)
        }
    }

    private static func validateMutationResponse(_ response: Operations.removeBottleFromCollection.Output) throws {
        switch response {
        case .ok:
            return
        case .badRequest:
            throw APIError.requestFailed("Invalid library request")
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("Library cannot be changed")
        case .notFound:
            throw APIError.notFound
        case .conflict:
            throw APIError.requestFailed("Library request conflicted with its current state")
        case .contentTooLarge:
            throw APIError.requestFailed("Library request was too large")
        case .internalServerError:
            throw APIError.serverError(500, "Unable to update library")
        case let .undocumented(status, _):
            throw APIError.unexpectedResponse(status)
        }
    }
}
