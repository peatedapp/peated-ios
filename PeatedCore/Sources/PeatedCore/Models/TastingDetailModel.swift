import Foundation

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
    private let tastingRepository: any TastingRepositoryProtocol
    private let isConnected: @MainActor () -> Bool
    private let cacheManager = CacheManager.shared
    private let database = DatabaseManager.shared

    public init(
        tastingId: String,
        seed: TastingFeedItem? = nil,
        tastingRepository: (any TastingRepositoryProtocol)? = nil,
        isConnected: @escaping @MainActor () -> Bool = { NetworkMonitor.shared.isConnected }
    ) {
        self.tastingId = tastingId
        self.seed = seed
        self.tastingRepository = tastingRepository ?? TastingRepository()
        self.isConnected = isConnected

        // If we have a navigation seed, render it immediately to avoid any skeleton
        if let seed {
            state = .loaded(TastingDetail(from: seed))
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
            let tasting = try await tastingRepository.getTasting(id: tastingId)
            let detail = TastingDetail(from: tasting)
            // Update state immediately (comments load separately)
            state = .loaded(detail)
            // Write-through cache for future loads/navigation
            try? await database.updateCachedTasting(tasting)
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
            let comments = try await tastingRepository.listComments(tastingId: tastingId)

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
        let connected = isConnected()
        let offlineOperation: OfflineOperation?

        if connected {
            offlineOperation = nil
        } else {
            do {
                offlineOperation = try OfflineOperation.toggleToast(
                    tastingId: tastingId,
                    isToasted: newToastedState
                )
            } catch {
                ToastManager.shared.showError("Failed to prepare offline toast")
                return
            }
        }

        detail.hasToasted = newToastedState
        detail.toastCount += newToastedState ? 1 : -1
        state = .loaded(detail)

        // Check network status for offline support
        if let offlineOperation {
            await OfflineQueueManager.shared.queueOperation(offlineOperation)
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
    @discardableResult
    public func postComment(_ text: String) async -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, tasting != nil, !isPostingComment else { return false }

        isPostingComment = true
        defer { isPostingComment = false }

        // Check network status for offline support
        if !isConnected() {
            do {
                let operation = try OfflineOperation.addComment(
                    tastingId: tastingId,
                    text: trimmedText
                )
                await OfflineQueueManager.shared.queueOperation(operation)
                ToastManager.shared.showInfo("Comment will post when online")
                return true
            } catch {
                ToastManager.shared.showError("Failed to prepare offline comment")
                return false
            }
        }

        do {
            let comment = try await tastingRepository.createComment(
                tastingId: tastingId,
                text: trimmedText
            )
            appendComment(comment)
            return true
        } catch {
            ToastManager.shared.showError("Failed to post comment")
            return false
        }
    }

    /// Deletes a comment
    public func deleteComment(_ comment: Comment) async {
        guard var detail = tasting,
              case let .loaded(comments) = commentState,
              comments.contains(where: { $0.id == comment.id }),
              !isDeletingComment
        else { return }

        isDeletingComment = true
        defer { isDeletingComment = false }

        // Optimistic removal
        let remainingComments = comments.filter { $0.id != comment.id }
        commentState = .loaded(remainingComments)
        detail.comments = remainingComments
        detail.commentCount = remainingComments.count
        state = .loaded(detail)

        do {
            try await tastingRepository.deleteComment(id: comment.id)
        } catch {
            commentState = .loaded(comments)
            detail.comments = comments
            detail.commentCount = comments.count
            state = .loaded(detail)
            ToastManager.shared.showError("Failed to delete comment")
        }
    }

    /// Deletes the tasting
    public func deleteTasting() async throws {
        try await tastingRepository.deleteTasting(id: tastingId)
    }

    /// Refreshes the tasting data
    public func refresh() async {
        await loadTasting()
    }

    private func appendComment(_ comment: Comment) {
        var comments: [Comment] = if case let .loaded(existingComments) = commentState {
            existingComments
        } else {
            []
        }

        guard !comments.contains(where: { $0.id == comment.id }) else { return }
        comments.append(comment)
        commentState = .loaded(comments)

        if var detail = tasting {
            detail.comments = comments
            detail.commentCount = comments.count
            state = .loaded(detail)
        }
    }
}
