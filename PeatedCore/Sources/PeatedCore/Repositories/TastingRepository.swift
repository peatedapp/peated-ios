import Foundation
import PeatedAPI

public protocol TastingRepositoryProtocol: Sendable {
    func getTasting(id: String) async throws -> TastingFeedItem
    func createTasting(_ input: CreateTastingInput) async throws -> TastingFeedItem
    func listComments(tastingId: String) async throws -> [Comment]
    func createComment(tastingId: String, text: String) async throws -> Comment
    func deleteComment(id: String) async throws
    func deleteTasting(id: String) async throws
    func toggleToast(tastingId: String) async throws -> Bool
}

public struct CreateTastingInput: Sendable {
    public let bottleId: String
    public let ratingBand: TastingRatingBand?
    public let notes: String?
    public let servingStyle: String?
    public let tags: [String]
    public let location: String?
    public let color: Int?
    public let pendingImageId: String?

    public init(
        bottleId: String,
        ratingBand: TastingRatingBand? = nil,
        notes: String? = nil,
        servingStyle: String? = nil,
        tags: [String] = [],
        location: String? = nil,
        color: Int? = nil,
        pendingImageId: String? = nil
    ) {
        self.bottleId = bottleId
        self.ratingBand = ratingBand
        self.notes = notes
        self.servingStyle = servingStyle
        self.tags = tags
        self.location = location
        self.color = color
        self.pendingImageId = pendingImageId
    }
}

public actor TastingRepository: TastingRepositoryProtocol, BaseRepositoryProtocol {
    public let apiClient: APIClient

    public init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    public func getTasting(id: String) async throws -> TastingFeedItem {
        let client = await client

        // Convert string ID to double
        guard let tastingId = Double(id) else {
            throw APIError.requestFailed("Invalid tasting ID")
        }

        let response = try await client.getTasting(
            path: .init(tasting: tastingId)
        )

        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(payload):
                // Map to TastingFeedItem
                return TastingFeedItem(
                    id: String(Int(payload.id)),
                    ratingBand: payload.ratingBand.map(TastingRatingBand.init),
                    notes: payload.notes,
                    servingStyle: payload.servingStyle?.rawValue,
                    imageUrl: payload.imageUrl,
                    createdAt: payload.createdAt,
                    userId: String(Int(payload.createdBy.id)),
                    username: payload.createdBy.username,
                    userDisplayName: nil,
                    userAvatarUrl: payload.createdBy.pictureUrl,
                    bottleId: String(Int(payload.bottle.id)),
                    bottleName: payload.bottle.fullName,
                    bottleBrandName: payload.bottle.brand.name,
                    bottleCategory: payload.bottle.category?.rawValue,
                    bottleImageUrl: payload.bottle.imageUrl,
                    toastCount: Int(payload.toasts),
                    commentCount: Int(payload.comments),
                    hasToasted: payload.hasToasted ?? false,
                    tags: payload.tags ?? [],
                    location: nil,
                    friendUsernames: payload.friends?.map(\.username) ?? []
                )
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

    public func createTasting(_ input: CreateTastingInput) async throws -> TastingFeedItem {
        let client = await client

        guard let bottleId = Int(input.bottleId) else {
            throw APIError.requestFailed("Invalid bottle ID")
        }

        let servingStyle: Operations.createTasting.Input.Body.jsonPayload.servingStylePayload? =
            input.servingStyle.flatMap { style in
                switch style {
                case "neat": .neat
                case "rocks": .rocks
                case "water", "splash": .splash
                default: nil
                }
            }

        // Build the request body
        let body = Operations.createTasting.Input.Body.json(
            .init(
                notes: input.notes,
                ratingBand: input.ratingBand?.createPayload,
                tags: input.tags.isEmpty ? nil : input.tags,
                color: input.color.flatMap { Double($0) },
                servingStyle: servingStyle,
                pendingImageId: input.pendingImageId,
                bottle: bottleId
            )
        )

        let response = try await client.createTasting(body: body)

        switch response {
        case let .ok(createdResponse):
            switch createdResponse.body {
            case let .json(payload):
                // Extract the tasting from the response payload
                let tasting = payload.tasting
                let apiUser = tasting.createdBy
                let apiBottle = tasting.bottle

                return TastingFeedItem(
                    id: String(Int(tasting.id)),
                    ratingBand: tasting.ratingBand.map(TastingRatingBand.init),
                    notes: tasting.notes,
                    servingStyle: tasting.servingStyle?.rawValue,
                    imageUrl: tasting.imageUrl,
                    createdAt: tasting.createdAt,
                    userId: String(Int(apiUser.id)),
                    username: apiUser.username,
                    userDisplayName: nil,
                    userAvatarUrl: apiUser.pictureUrl,
                    bottleId: String(Int(apiBottle.id)),
                    bottleName: apiBottle.fullName,
                    bottleBrandName: apiBottle.brand.name,
                    bottleCategory: apiBottle.category?.rawValue,
                    bottleImageUrl: apiBottle.imageUrl,
                    toastCount: Int(tasting.toasts),
                    commentCount: Int(tasting.comments),
                    hasToasted: tasting.hasToasted ?? false,
                    tags: tasting.tags ?? [],
                    location: nil,
                    friendUsernames: tasting.friends?.map(\.username) ?? []
                )
            }
        case .badRequest:
            throw APIError.requestFailed("Invalid tasting data")
        case .unauthorized:
            throw APIError.unauthorized
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    public func listComments(tastingId: String) async throws -> [Comment] {
        let client = await client

        guard let id = Double(tastingId) else {
            throw APIError.requestFailed("Invalid tasting ID")
        }

        let response = try await client.listComments(
            query: .init(tasting: id, limit: 100)
        )

        guard case let .ok(okResponse) = response else {
            switch response {
            case .unauthorized:
                throw APIError.unauthorized
            case .notFound:
                throw APIError.notFound
            case let .undocumented(statusCode, _):
                throw APIError.unexpectedResponse(statusCode)
            default:
                throw APIError.requestFailed("Unable to load comments")
            }
        }

        switch okResponse.body {
        case let .json(payload):
            return payload.results.map { Comment(from: $0, tastingId: tastingId) }
        }
    }

    public func createComment(tastingId: String, text: String) async throws -> Comment {
        let client = await client

        guard let id = Double(tastingId) else {
            throw APIError.requestFailed("Invalid tasting ID")
        }

        let response = try await client.createComment(
            path: .init(tasting: id),
            body: .json(.init(comment: text, createdAt: Date()))
        )

        guard case let .ok(okResponse) = response else {
            switch response {
            case .unauthorized:
                throw APIError.unauthorized
            case .notFound:
                throw APIError.notFound
            case let .undocumented(statusCode, _):
                throw APIError.unexpectedResponse(statusCode)
            default:
                throw APIError.requestFailed("Unable to post comment")
            }
        }

        switch okResponse.body {
        case let .json(payload):
            return Comment(from: payload, tastingId: tastingId)
        }
    }

    public func deleteComment(id: String) async throws {
        let client = await client

        guard let commentId = Double(id) else {
            throw APIError.requestFailed("Invalid comment ID")
        }

        let response = try await client.deleteComment(
            path: .init(comment: commentId)
        )

        switch response {
        case .ok:
            return
        case .badRequest:
            throw APIError.requestFailed("Invalid comment request")
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("You cannot delete this comment")
        case .notFound:
            throw APIError.notFound
        case .conflict:
            throw APIError.requestFailed("Comment could not be deleted")
        case .contentTooLarge:
            throw APIError.requestFailed("Comment response was too large")
        case .internalServerError:
            throw APIError.serverError(500, "Unable to delete comment")
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        }
    }

    public func deleteTasting(id: String) async throws {
        let client = await client

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
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    public func toggleToast(tastingId: String) async throws -> Bool {
        let client = await client

        guard let id = Double(tastingId) else {
            throw APIError.requestFailed("Invalid tasting ID")
        }

        // First, check if already toasted
        let detailsResponse = try await client.getTasting(
            path: .init(tasting: id)
        )

        guard case let .ok(okResponse) = detailsResponse,
              case let .json(payload) = okResponse.body
        else {
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
