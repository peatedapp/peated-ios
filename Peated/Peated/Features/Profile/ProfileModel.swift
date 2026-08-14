import Observation
import PeatedCore
import SwiftUI

@Observable
@MainActor
class ProfileModel {
    var user: User?
    var achievements: [Achievement] = []
    var isLoading = false
    var error: Error?
    var isTogglingFriend = false
    var isPrimed = false
    var statsPrimed = false

    // Favorites (for profile)
    var favorites: [Bottle] = []
    var isLoadingFavorites = false
    var favoritesError: Error?

    // Optional userId - if nil, shows current user
    let userId: String?
    private let seed: User?

    private let authManager = AuthenticationManager.shared
    private let achievementsRepository: AchievementsRepository
    private let userRepository: UserRepository
    private let collectionRepository: CollectionRepository

    private func mergedUser(_ seed: User?, with cached: User?) -> User? {
        guard let seed else { return cached }
        guard let cached else { return seed }
        var u = seed
        // Prefer any non-default values from cache
        if !cached.email.isEmpty {
            u = User(
                id: u.id,
                email: cached.email,
                username: u.username,
                verified: cached.verified,
                admin: cached.admin,
                mod: cached.mod
            )
        }
        u.pictureUrl = cached.pictureUrl ?? u.pictureUrl
        // Stats
        u.tastingsCount = max(u.tastingsCount, cached.tastingsCount)
        u.bottlesCount = max(u.bottlesCount, cached.bottlesCount)
        u.collectedCount = max(u.collectedCount, cached.collectedCount)
        u.contributionsCount = max(u.contributionsCount, cached.contributionsCount)
        // Relationship
        u.friendStatus = cached.friendStatus ?? u.friendStatus
        return u
    }

    init(userId: String? = nil, seed: User? = nil) {
        self.userId = userId
        self.seed = seed

        // Create API client - using the same configuration as AuthenticationManager
        let apiClient = APIClient(
            serverURL: URL(string: "https://api.peated.com/v1")!
        )
        achievementsRepository = AchievementsRepository(apiClient: apiClient)
        userRepository = UserRepository(apiClient: apiClient)
        collectionRepository = CollectionRepository(apiClient: apiClient)
        let targetUserId = userId
        let profileRepository = userRepository

        // Capture a minimal seed snapshot (optional)
        let seedSnapshot: UserProfileSnapshot? = {
            if let seed {
                return UserProfileSnapshot(id: seed.id, username: seed.username, pictureUrl: seed.pictureUrl)
            }
            if userId == nil, let current = authManager.currentUser {
                return UserProfileSnapshot(id: current.id, username: current.username, pictureUrl: current.pictureUrl)
            }
            return nil
        }()

        Task { [weak self] in
            guard let self else { return }
            // Determine target id
            guard let id = self.userId ?? seed?.id ?? authManager.currentUser?.id else { return }

            // Use SWR helper to produce initial snapshot & refresh in background
            let initial = await SWR.snapshot(
                seed: seedSnapshot,
                readSnapshot: { await SnapshotStore.getUser(id) },
                fetchFull: {
                    if let targetUserId {
                        try await profileRepository.getUser(id: targetUserId)
                    } else {
                        try await profileRepository.getCurrentUser()
                    }
                },
                writeSnapshot: { user in
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
                },
                merge: { seed, cached in SnapshotStore.merge(seed, cached) },
                onChanged: { [weak self] snap in
                    await self?.applySnapshot(snap)
                }
            )

            if let initial {
                applySnapshot(initial)
            }
            isPrimed = (user != nil)
        }
    }

    func loadUser() async {
        isLoading = true
        error = nil
        // Network refresh still happens via SWR init; keep this in case caller expects explicit reload behavior.
        let result: (user: User?, achievements: [Achievement], error: Error?)
        do {
            if let userId {
                // Load specific user from API
                let loadedUser = try await userRepository.getUser(id: userId)

                // Load achievements for specific user
                let loadedAchievements = try await achievementsRepository.getUserBadges(userId: userId)

                result = (user: loadedUser, achievements: loadedAchievements, error: nil)
            } else {
                // Get the current user from auth manager
                let currentUser = authManager.currentUser

                // Fetch current user's achievements from the API
                let loadedAchievements = try await achievementsRepository.getCurrentUserBadges()

                result = (user: currentUser, achievements: loadedAchievements, error: nil)
            }
        } catch {
            result = (user: nil, achievements: [], error: error)
        }

        // Update properties on main actor
        user = result.user
        achievements = result.achievements
        error = result.error
        isLoading = false
        statsPrimed = (result.user != nil)

        // Warm recent activity from cache immediately (no network) and optionally refresh
        _ = await loadRecentFromCache()
    }

    /// Loads recent activity for the profile from cached MRU IDs and DB tasting cache
    func loadRecentFromCache(limit: Int = 10) async -> [TastingFeedItem] {
        guard let id = user?.id ?? userId else { return [] }
        let ids = await SnapshotStore.getUserRecent(userId: id, limit: limit)
        if ids.isEmpty {
            return []
        }
        var items: [TastingFeedItem] = []
        for tid in ids {
            if let cached = try? await DatabaseManager.shared.getCachedTasting(id: tid) {
                items.append(cached.tasting)
            }
        }
        return items
    }

    private func applySnapshot(_ snap: UserProfileSnapshot) {
        var u = user ?? User(id: snap.id, email: "", username: snap.username ?? "")
        if let v = snap.username {
            u = User(id: u.id, email: u.email, username: v, verified: u.verified, admin: u.admin, mod: u.mod)
        }
        if let v = snap.pictureUrl {
            u.pictureUrl = v
        }
        if let v = snap.tastingsCount {
            u.tastingsCount = v
        }
        if let v = snap.bottlesCount {
            u.bottlesCount = v
        }
        if let v = snap.collectedCount {
            u.collectedCount = v
        }
        if let v = snap.contributionsCount {
            u.contributionsCount = v
        }
        if let v = snap.friendStatus {
            u.friendStatus = v
        }
        user = u
        statsPrimed = statsPrimed ||
            (snap.tastingsCount != nil || snap.bottlesCount != nil || snap.collectedCount != nil || snap
                .contributionsCount != nil)
    }

    func logout() async {
        isLoading = true
        await authManager.logout()
        isLoading = false

        // The app will automatically navigate back to login
        // because AppView observes the auth state
    }

    func toggleFriendship() async {
        guard let targetId = user?.id else { return }
        isTogglingFriend = true
        defer { isTogglingFriend = false }
        do {
            switch user?.friendStatus {
            case .friends:
                // Unfriend
                try await userRepository.unfollowUser(id: targetId)
                user?.friendStatus = User.FriendStatus.none
            case .pending:
                // Cancel request
                try await userRepository.unfollowUser(id: targetId)
                user?.friendStatus = User.FriendStatus.none
            default:
                // Send request
                try await userRepository.followUser(id: targetId)
                user?.friendStatus = User.FriendStatus.pending
            }
        } catch {
            self.error = error
        }
    }

    @MainActor
    func loadFavorites() async {
        isLoadingFavorites = true
        favoritesError = nil
        defer { isLoadingFavorites = false }

        // Determine which user to load favorites for
        let userKey: String = if let targetId = userId ?? user?.id {
            targetId
        } else {
            "me"
        }

        do {
            if let favId = try await collectionRepository.getFavoritesCollectionId(user: userKey) {
                let items = try await collectionRepository.listBottles(in: favId, user: userKey)
                favorites = items
            } else {
                favorites = []
            }
        } catch {
            favoritesError = error
        }
    }
}
