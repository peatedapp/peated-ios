import Foundation
import PeatedAPI

public protocol UserRepositoryProtocol: Sendable {
    func getCurrentUser() async throws -> User
    func getUser(id: String) async throws -> User
    func updateProfile(_ input: UpdateProfileInput) async throws -> User
    func followUser(id: String) async throws
    func unfollowUser(id: String) async throws
    /// Schedules the signed-in member's account for deletion and returns the member with `deletionScheduledAt` set.
    func requestAccountDeletion(appleAuthorizationCode: String?) async throws -> User
    /// Cancels a pending deletion and returns the member with `deletionScheduledAt` cleared.
    func cancelAccountDeletion() async throws -> User
    /// Blocks a member. Any friendship or pending request between you ends. Blocking again changes nothing.
    func blockUser(id: String) async throws
    /// Removes your block on a member. Unblocking someone you have not blocked changes nothing.
    func unblockUser(id: String) async throws
    /// One page of the signed-in member's block list, newest first. Cursors start at 1.
    func listBlockedUsers(cursor: Int, limit: Int) async throws -> BlockedUsersPage
}

public struct UpdateProfileInput: Sendable {
    public let displayName: String?
    public let bio: String?
    public let location: String?

    public init(displayName: String? = nil, bio: String? = nil, location: String? = nil) {
        self.displayName = displayName
        self.bio = bio
        self.location = location
    }
}

public actor UserRepository: UserRepositoryProtocol, BaseRepositoryProtocol {
    public let apiClient: APIClient

    public init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    public func getCurrentUser() async throws -> User {
        let client = await client
        let response = try await client.getMe()

        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(payload):
                var user = User(from: payload.user)

                // Fetch additional user details including stats
                do {
                    let detailsResponse = try await client.getUser(
                        path: .init(user: .init(value1: payload.user.id))
                    )

                    if case let .ok(detailsOk) = detailsResponse,
                       case let .json(detailsJson) = detailsOk.body {
                        user.tastingsCount = Int(detailsJson.stats.tastings)
                        user.bottlesCount = Int(detailsJson.stats.bottles)
                        user.collectedCount = Int(detailsJson.stats.collected)
                        user.contributionsCount = Int(detailsJson.stats.contributions)
                    }
                } catch {
                    // Continue without stats if details fail
                    Telemetry.capture(error, feature: "user", operation: "load_user_details")
                }

                // Write-through caches
                await NormalizedStore.shared.upsert(.user(user.id), value: user)
                await SnapshotStore.upsertUser(UserProfileSnapshot(
                    id: user.id,
                    username: user.username,
                    pictureUrl: user.pictureUrl,
                    tastingsCount: user.tastingsCount,
                    bottlesCount: user.bottlesCount,
                    collectedCount: user.collectedCount,
                    contributionsCount: user.contributionsCount,
                    friendStatus: user.friendStatus
                ))
                return user
            }
        case .unauthorized:
            throw APIError.unauthorized
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    public func getUser(id: String) async throws -> User {
        print("UserRepository.getUser called with id: \(id)")
        let client = await client

        // Create the user payload
        let userPayload: Operations.getUser.Input.Path.userPayload
        if let userId = Double(id), userId == floor(userId) {
            // Convert to integer to avoid decimal URLs like /users/1.0
            print("Using numeric ID: \(Int(userId))")
            userPayload = .init(value1: Double(Int(userId)))
        } else {
            // Assume it's a username
            print("Using username: \(id)")
            userPayload = .init(value3: id)
        }

        print("Making API call to get user...")
        let response = try await client.getUser(
            path: .init(user: userPayload)
        )
        print("API call completed")

        switch response {
        case let .ok(okResponse):
            switch okResponse.body {
            case let .json(payload):
                var user = User(
                    id: String(Int(payload.id)),
                    email: payload.email ?? "",
                    username: payload.username,
                    verified: payload.verified ?? false,
                    admin: payload.admin ?? false,
                    mod: payload.mod ?? false
                )
                user.pictureUrl = payload.pictureUrl
                // Map friendship status if available
                if let status = payload.friendStatus?.rawValue {
                    user.friendStatus = User.FriendStatus(rawValue: status)
                }

                // Add stats
                user.tastingsCount = Int(payload.stats.tastings)
                user.bottlesCount = Int(payload.stats.bottles)
                user.collectedCount = Int(payload.stats.collected)
                user.contributionsCount = Int(payload.stats.contributions)

                // Write-through caches
                await NormalizedStore.shared.upsert(.user(user.id), value: user)
                await SnapshotStore.upsertUser(UserProfileSnapshot(
                    id: user.id,
                    username: user.username,
                    pictureUrl: user.pictureUrl,
                    tastingsCount: user.tastingsCount,
                    bottlesCount: user.bottlesCount,
                    collectedCount: user.collectedCount,
                    contributionsCount: user.contributionsCount,
                    friendStatus: user.friendStatus
                ))
                return user
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

    public func updateProfile(_ input: UpdateProfileInput) async throws -> User {
        // Build the update body - users_update doesn't exist in API, return current user for now
        // TODO: Implement when API supports profile updates
        _ = input
        return try await getCurrentUser()
    }

    public func followUser(id: String) async throws {
        let client = await client

        guard let userId = Double(id) else {
            throw APIError.requestFailed("Invalid user ID")
        }

        let response = try await client.addFriend(
            .init(path: .init(user: userId))
        )

        switch response {
        case .ok:
            return
        case .badRequest:
            throw APIError.requestFailed("Cannot follow this user")
        case .unauthorized:
            throw APIError.unauthorized
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    public func unfollowUser(id: String) async throws {
        let client = await client

        guard let userId = Double(id) else {
            throw APIError.requestFailed("Invalid user ID")
        }

        let response = try await client.removeFriend(
            .init(path: .init(user: userId))
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

    // MARK: - Account deletion

    /// Only the signed-in member can delete their account, so the path is always `me`.
    /// The server ignores `appleAuthorizationCode` unless the account has an Apple identity.
    public func requestAccountDeletion(appleAuthorizationCode: String?) async throws -> User {
        let client = await client
        let response = try await client.deleteUser(
            path: .init(user: .init(value3: "me")),
            body: appleAuthorizationCode.map {
                Operations.deleteUser.Input.Body.json(.init(appleAuthorizationCode: $0))
            }
        )

        switch response {
        case let .ok(ok):
            switch ok.body {
            case let .json(payload):
                return User(from: payload)
            }
        case .badRequest:
            // Apple refused the authorization code. Nothing was scheduled.
            throw APIError.requestFailed("Apple did not accept the sign-in. Try Sign in with Apple again.")
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("You can only delete your own account.")
        case .notFound:
            throw APIError.notFound
        case .internalServerError:
            throw APIError.serverError(500, "We couldn't schedule the deletion. Nothing has changed. Try again.")
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    public func cancelAccountDeletion() async throws -> User {
        let client = await client
        let response = try await client.cancelUserDeletion(path: .init(user: .init(value3: "me")))

        switch response {
        case let .ok(ok):
            switch ok.body {
            case let .json(payload):
                return User(from: payload)
            }
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("You can only cancel your own account deletion.")
        case .notFound:
            throw APIError.notFound
        case .internalServerError:
            throw APIError.serverError(500, "We couldn't cancel the deletion. It's still scheduled. Try again.")
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    // MARK: - Blocking

    public func blockUser(id: String) async throws {
        let client = await client
        let path = try Self.blockPath(id)
        let response = try await client.blockUser(path: .init(user: path))

        switch response {
        case .ok:
            return
        case .badRequest:
            throw APIError.requestFailed("You can't block yourself.")
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("Your account can't block members right now.")
        case .notFound:
            throw APIError.notFound
        case .internalServerError:
            throw APIError.serverError(500, "We couldn't block this member. Try again.")
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    public func unblockUser(id: String) async throws {
        let client = await client
        let path = try Self.unblockPath(id)
        let response = try await client.unblockUser(path: .init(user: path))

        switch response {
        case .ok:
            return
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("Your account can't change blocks right now.")
        case .notFound:
            throw APIError.notFound
        case .internalServerError:
            throw APIError.serverError(500, "We couldn't unblock this member. Try again.")
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    /// Only your own list is available, so the path is always `me`.
    public func listBlockedUsers(cursor: Int, limit: Int) async throws -> BlockedUsersPage {
        let client = await client
        let response = try await client.listBlockedUsers(
            path: .init(user: .init(value3: "me")),
            query: .init(cursor: Double(cursor), limit: Double(limit))
        )

        switch response {
        case let .ok(ok):
            switch ok.body {
            case let .json(payload):
                let users = payload.results.map { entry in
                    var user = User(
                        id: entry.user.id,
                        email: entry.user.email,
                        username: entry.user.username,
                        verified: entry.user.verified,
                        admin: entry.user.admin,
                        mod: entry.user.mod
                    )
                    user.pictureUrl = entry.user.pictureUrl
                    return BlockedUser(user: user, blockedAt: entry.createdAt)
                }
                return BlockedUsersPage(users: users, nextCursor: payload.rel.nextCursor.map { Int($0) })
            }
        case .unauthorized:
            throw APIError.unauthorized
        case .forbidden:
            throw APIError.requestFailed("You can only view your own blocked members.")
        case let .undocumented(statusCode, _):
            throw APIError.unexpectedResponse(statusCode)
        default:
            throw APIError.invalidResponse
        }
    }

    /// The block routes take a numeric ID; usernames are not accepted here.
    static func blockPath(_ id: String) throws -> Operations.blockUser.Input.Path.userPayload {
        guard let userId = Int(id), userId > 0 else {
            throw APIError.requestFailed("Invalid user ID")
        }
        return .init(value1: Double(userId))
    }

    static func unblockPath(_ id: String) throws -> Operations.unblockUser.Input.Path.userPayload {
        guard let userId = Int(id), userId > 0 else {
            throw APIError.requestFailed("Invalid user ID")
        }
        return .init(value1: Double(userId))
    }
}
