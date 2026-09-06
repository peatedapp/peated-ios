import Foundation
import PeatedAPI

public protocol BottleRepositoryProtocol: Sendable {
    func searchBottles(query: String, limit: Int) async throws -> [Bottle]
    func createBottle(_ input: CreateBottleInput) async throws -> Bottle
    func getBottle(barcode: String) async throws -> Bottle
    func getBottle(id: String) async throws -> Bottle
    func getPopularBottles(limit: Int) async throws -> [Bottle]
    func getTopRatedBottles(limit: Int) async throws -> [Bottle]
    func getEntityBottles(entityId: String) async throws -> [Bottle]
    func getSuggestedTags(bottleId: String) async throws -> [TastingTag]
    // TODO: Add when API endpoint is available
    // func getBottleSuggestions(prefix: String) async throws -> [Bottle]
}

public actor BottleRepository: BottleRepositoryProtocol, BaseRepositoryProtocol {
    public let apiClient: APIClient

    public init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    public func searchBottles(query: String, limit: Int = 20) async throws -> [Bottle] {
        let client = await client

        let response = try await client.listBottles(
            query: .init(
                query: query,
                limit: Double(limit)
            )
        )

        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(payload):
                return payload.results.map { apiBottle in
                    let bottle = Bottle(from: apiBottle)
                    Task { await NormalizedStore.shared.upsert(.bottle(bottle.id), value: bottle) }
                    return bottle
                }
            }
        case .badRequest:
            throw APIError.requestFailed("Invalid search query")
        case .unauthorized:
            throw APIError.unauthorized
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    public func createBottle(_ input: CreateBottleInput) async throws -> Bottle {
        let client = await client
        let response = try await client.createBottle(
            body: .json(Self.makeCreatePayload(input))
        )

        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(payload):
                let bottle = Bottle(from: payload)
                await cache(bottle)
                return bottle
            }
        case .badRequest:
            throw APIError.requestFailed("Check the bottle details and try again.")
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("A verified account is required to add a bottle.")
        case .notFound:
            throw APIError.notFound
        case .conflict:
            throw APIError.requestFailed("A matching bottle already exists. Search for it instead.")
        case .contentTooLarge:
            throw APIError.requestFailed("The bottle data is too large.")
        case .internalServerError:
            throw APIError.serverError(500, nil)
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        }
    }

    public func getBottle(barcode: String) async throws -> Bottle {
        let client = await client
        let response = try await client.getBottleBarcode(
            path: .init(barcode: barcode)
        )

        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(payload):
                let bottle = Bottle(from: payload.bottle)
                await cache(bottle)
                return bottle
            }
        case .badRequest:
            throw APIError.requestFailed("That barcode is not a valid GTIN.")
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("Barcode lookup is unavailable for this account.")
        case .notFound:
            throw APIError.notFound
        case .conflict:
            throw APIError.requestFailed("That barcode has conflicting bottle matches.")
        case .contentTooLarge:
            throw APIError.requestFailed("That barcode is too long.")
        case .internalServerError:
            throw APIError.serverError(500, nil)
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        }
    }

    public func getBottle(id: String) async throws -> Bottle {
        let client = await client

        guard let bottleId = Double(id) else {
            throw APIError.requestFailed("Invalid bottle ID")
        }

        let response = try await client.getBottle(
            path: .init(bottle: bottleId)
        )

        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(payload):
                let bottle = Bottle(from: payload.value1)
                await NormalizedStore.shared.upsert(.bottle(bottle.id), value: bottle)
                await SnapshotStore.upsertBottle(BottleSnapshot(
                    id: bottle.id,
                    fullName: bottle.fullName,
                    brandId: bottle.brand.id,
                    brandName: bottle.brand.name,
                    imageUrl: bottle.imageUrl
                ))
                return bottle
            }
        case .unauthorized:
            throw APIError.unauthorized
        case .notFound:
            throw APIError.notFound
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    static func makeCreatePayload(
        _ input: CreateBottleInput
    ) -> Operations.createBottle.Input.Body.jsonPayload {
        typealias Payload = Operations.createBottle.Input.Body.jsonPayload

        let category = input.category.flatMap { Payload.categoryPayload(rawValue: $0.rawValue) }

        let brand = Payload.brandPayload(
            value1: .init(name: input.brandName, kind: .brand)
        )

        return Payload(
            name: input.name,
            statedAge: input.statedAge,
            category: category,
            brand: brand,
            abv: input.abv
        )
    }

    private func cache(_ bottle: Bottle) async {
        await NormalizedStore.shared.upsert(.bottle(bottle.id), value: bottle)
        await SnapshotStore.upsertBottle(BottleSnapshot(
            id: bottle.id,
            fullName: bottle.fullName,
            brandId: bottle.brand.id,
            brandName: bottle.brand.name,
            imageUrl: bottle.imageUrl
        ))
    }

    public func getPopularBottles(limit: Int = 10) async throws -> [Bottle] {
        let client = await client

        // Fetch bottles sorted by total tastings (most popular)
        let response = try await client.listBottles(
            query: .init(
                limit: Double(limit),
                sort: ._hyphen_tastings
            )
        )

        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(payload):
                return payload.results.map { apiBottle in
                    let bottle = Bottle(from: apiBottle)
                    Task { await NormalizedStore.shared.upsert(.bottle(bottle.id), value: bottle) }
                    return bottle
                }
            }
        case .badRequest:
            throw APIError.requestFailed("Failed to fetch popular bottles")
        case .unauthorized:
            throw APIError.unauthorized
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    public func getTopRatedBottles(limit: Int = 10) async throws -> [Bottle] {
        let client = await client

        // Fetch bottles sorted by rating (highest rated)
        let response = try await client.listBottles(
            query: .init(
                limit: Double(limit),
                sort: ._hyphen_score
            )
        )

        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(payload):
                return payload.results.map { apiBottle in
                    Bottle(from: apiBottle)
                }
            }
        case .badRequest:
            throw APIError.requestFailed("Failed to fetch top rated bottles")
        case .unauthorized:
            throw APIError.unauthorized
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    public func getEntityBottles(entityId: String) async throws -> [Bottle] {
        let client = await client

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
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(payload):
                return payload.results.map { apiBottle in
                    let bottle = Bottle(from: apiBottle)
                    Task { await NormalizedStore.shared.upsert(.bottle(bottle.id), value: bottle) }
                    return bottle
                }
            }
        case .badRequest:
            throw APIError.requestFailed("Failed to fetch entity bottles")
        case .unauthorized:
            throw APIError.unauthorized
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    public func getSuggestedTags(bottleId: String) async throws -> [TastingTag] {
        let client = await client

        guard let bottleId = Double(bottleId) else {
            throw APIError.requestFailed("Invalid bottle ID")
        }

        let response = try await client.getBottleSuggestedTags(path: .init(bottle: bottleId))

        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(payload):
                return payload.results.map { result in
                    TastingTag(
                        name: result.tag.name,
                        category: result.tag.tagCategory.rawValue,
                        synonyms: result.tag.synonyms,
                        usageCount: Int(result.count)
                    )
                }
            }
        case .badRequest:
            throw APIError.requestFailed("Invalid bottle ID")
        case .unauthorized:
            throw APIError.unauthorized
        case .notFound:
            throw APIError.notFound
        case let .undocumented(statusCode, _):
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
