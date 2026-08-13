import Foundation
import PeatedAPI

/// Model for managing tasting detail view state and data
@Observable
@MainActor
public class TastingDetailModel {
    /// State
    public enum ViewState: Equatable {
        case loading
        case loaded(TastingDetail)
        case error(String)
    }

    public enum CommentState: Equatable {
        case loading
        case loaded([Comment])
        case error(String)
    }

    public private(set) var state: ViewState = .loading
    public private(set) var commentState: CommentState = .loading
    public private(set) var isPostingComment = false
    public private(set) var isDeletingComment = false

    /// Data
    public var tasting: TastingDetail? {
        if case let .loaded(detail) = state {
            return detail
        }
        return nil
    }

    // Dependencies
    private let tastingId: String
    private let seed: TastingFeedItem?
    private let tastingRepository: TastingRepository
    private let apiClient: APIClient
    private let cacheManager = CacheManager.shared
    private let database = DatabaseManager.shared

    public init(
        tastingId: String,
        seed: TastingFeedItem? = nil,
        tastingRepository: TastingRepository? = nil
    ) {
        self.tastingId = tastingId
        self.seed = seed

        // Create API client
        let apiClient = APIClient(
            serverURL: URL(string: "https://api.peated.com/v1")!
        )
        self.apiClient = apiClient
        self.tastingRepository = tastingRepository ?? TastingRepository(apiClient: apiClient)

        // If we have a navigation seed, render it immediately to avoid any skeleton
        if let seed {
            let seeded = TastingDetail(from: seed)
            state = .loaded(seeded)
            // Kick off background work without waiting for view lifecycle
            Task { await self.loadComments() }
            Task { await self.refreshFromNetworkAndUpdate() }
        }
    }

    /// Loads the full tasting details including comments
    public func loadTasting() async {
        // 0) Seed from navigation if provided (fastest)
        if let seed {
            let seeded = TastingDetail(from: seed)
            state = .loaded(seeded)
            Task { await self.loadComments() }
            Task { await self.refreshFromNetworkAndUpdate() }
            return
        }

        // 1) Seed from cache (fast-path) to avoid flicker
        if let cached = try? await database.getCachedTasting(id: tastingId) {
            let seeded = TastingDetail(from: cached.tasting)
            state = .loaded(seeded)
            // Load comments asynchronously
            Task { await self.loadComments() }
            // Refresh details in background and update cache/state when complete
            Task { await self.refreshFromNetworkAndUpdate() }
            return
        }

        // 2) Fallback: no cache available, do a normal network load
        state = .loading
        await refreshFromNetworkAndUpdate()
    }

    private func refreshFromNetworkAndUpdate() async {
        do {
            let client = await apiClient.generatedClient
            let response = try await client.getTasting(
                .init(path: .init(tasting: Double(tastingId) ?? 0))
            )
            guard case let .ok(okResponse) = response, case let .json(payload) = okResponse.body else {
                state = .error("Failed to load tasting")
                return
            }
            let detail = TastingDetail(
                id: String(Int(payload.id)),
                rating: extractRating(from: payload.rating),
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
                comments: [],
                toasts: []
            )
            // Update state immediately (comments load separately)
            state = .loaded(detail)
            // Write-through cache for future loads/navigation
            try? await database.updateCachedTasting(detail.toFeedItem())
            // Ensure comments get loaded
            await loadComments()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Loads comments for the tasting
    public func loadComments() async {
        commentState = .loading

        do {
            // Use the actual listComments API endpoint
            let client = await apiClient.generatedClient
            let response = try await client.listComments(
                .init(
                    query: .init(
                        tasting: Double(tastingId) ?? 0,
                        limit: 100 // Load up to 100 comments
                    )
                )
            )

            guard case let .ok(okResponse) = response,
                  case let .json(payload) = okResponse.body
            else {
                commentState = .error("Failed to load comments")
                return
            }

            // Map API comments to our Comment model
            let comments = payload.results.map { apiComment in
                Comment(
                    id: String(Int(apiComment.id)),
                    text: apiComment.comment,
                    createdAt: apiComment.createdAt,
                    userId: String(Int(apiComment.createdBy.id)),
                    username: apiComment.createdBy.username,
                    userDisplayName: nil, // API doesn't provide separate display name
                    userAvatarUrl: apiComment.createdBy.pictureUrl,
                    tastingId: tastingId
                )
            }

            commentState = .loaded(comments)

            // Update the tasting detail with comments if loaded
            if case var .loaded(detail) = state {
                detail.comments = comments
                detail.commentCount = comments.count
                state = .loaded(detail)
            }

        } catch {
            commentState = .error("Failed to load comments")
            // Don't fail the whole view, just show error for comments
        }
    }

    /// Toggles the toast state for the current tasting
    public func toggleToast() async {
        guard var detail = tasting else { return }

        // Optimistic update
        let newToastedState = !detail.hasToasted
        detail.hasToasted = newToastedState
        detail.toastCount += newToastedState ? 1 : -1
        state = .loaded(detail)

        // Check network status for offline support
        if !NetworkMonitor.shared.isConnected {
            let operation = OfflineOperation.toggleToast(
                tastingId: tastingId,
                isToasted: newToastedState
            )
            await OfflineQueueManager.shared.queueOperation(operation)
            ToastManager.shared.showInfo("Toast will sync when online")
            return
        }

        // Perform API call
        do {
            let actualToastedState = try await tastingRepository.toggleToast(tastingId: tastingId)

            // Update with actual state
            detail.hasToasted = actualToastedState
            detail.toastCount += actualToastedState ? 0 : -1
            state = .loaded(detail)

            if actualToastedState {
                ToastManager.shared.showSuccess("Cheers! 🥃")
            }

        } catch {
            // Revert on error
            detail.hasToasted = !newToastedState
            detail.toastCount += newToastedState ? -1 : 1
            state = .loaded(detail)

            ToastManager.shared.showError("Failed to update toast")
        }
    }

    /// Posts a new comment on the tasting
    public func postComment(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard tasting != nil else { return }

        isPostingComment = true
        defer { isPostingComment = false }

        // Check network status for offline support
        if !NetworkMonitor.shared.isConnected {
            let operation = OfflineOperation.addComment(
                tastingId: tastingId,
                text: text
            )
            await OfflineQueueManager.shared.queueOperation(operation)
            ToastManager.shared.showInfo("Comment will post when online")
            return
        }

        // TODO: Implement when createComment API is available
        ToastManager.shared.showInfo("Comment posting not yet implemented")
    }

    /// Deletes a comment
    public func deleteComment(_ comment: Comment) async {
        guard var detail = tasting else { return }

        isDeletingComment = true
        defer { isDeletingComment = false }

        // Optimistic removal
        detail.comments.removeAll { $0.id == comment.id }
        detail.commentCount = max(0, detail.commentCount - 1)
        state = .loaded(detail)

        // TODO: Implement when deleteComment API is available
        ToastManager.shared.showInfo("Comment deletion not yet implemented")
    }

    /// Deletes the tasting
    public func deleteTasting() async throws {
        // TODO: Implement when deleteTasting API is available
        throw APIError.notImplemented
    }

    /// Refreshes the tasting data
    public func refresh() async {
        await loadTasting()
    }
}
