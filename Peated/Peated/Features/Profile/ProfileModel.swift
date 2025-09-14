import SwiftUI
import PeatedCore
import Observation

@Observable
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
    guard let seed = seed else { return cached }
    guard let cached = cached else { return seed }
    var u = seed
    // Prefer any non-default values from cache
    if !cached.email.isEmpty { u = User(id: u.id, email: cached.email, username: u.username, verified: cached.verified, admin: cached.admin, mod: cached.mod) }
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
    self.achievementsRepository = AchievementsRepository(apiClient: apiClient)
    self.userRepository = UserRepository(apiClient: apiClient)
    self.collectionRepository = CollectionRepository(apiClient: apiClient)

    // Capture a minimal seed snapshot (optional)
    let seedSnapshot: UserProfileSnapshot? = {
      if let seed { return UserProfileSnapshot(id: seed.id, username: seed.username, pictureUrl: seed.pictureUrl) }
      if userId == nil, let current = authManager.currentUser { return UserProfileSnapshot(id: current.id, username: current.username, pictureUrl: current.pictureUrl) }
      return nil
    }()

    Task { [weak self] in
      guard let self else { return }
      // Determine target id
      guard let id = self.userId ?? seed?.id ?? self.authManager.currentUser?.id else { return }

      // Use SWR helper to produce initial snapshot & refresh in background
      let initial = await SWR.snapshot(
        seed: seedSnapshot,
        readSnapshot: { await SnapshotStore.getUser(id) },
        fetchFull: {
          if let target = self.userId { return try await self.userRepository.getUser(id: target) }
          else { return try await self.userRepository.getCurrentUser() }
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
        merge: SnapshotStore.merge,
        onChanged: { [weak self] snap in
          await MainActor.run {
            self?.applySnapshot(snap)
          }
        }
      )

      await MainActor.run {
        if let initial { self.applySnapshot(initial) }
        self.isPrimed = (self.user != nil)
      }
    }
  }
  
  func loadUser() async {
    isLoading = true
    error = nil
    // Network refresh still happens via SWR init; keep this in case caller expects explicit reload behavior.
    let result = await Task.detached {
      do {
        if let userId = self.userId {
          // Load specific user from API
          let loadedUser = try await self.userRepository.getUser(id: userId)
          
          // Load achievements for specific user
          let loadedAchievements = try await self.achievementsRepository.getUserBadges(userId: userId)
          
          return (user: Optional(loadedUser), achievements: loadedAchievements, error: nil as Error?)
        } else {
          // Get the current user from auth manager
          let currentUser = self.authManager.currentUser
          
          // Fetch current user's achievements from the API
          let loadedAchievements = try await self.achievementsRepository.getCurrentUserBadges()
          
          return (user: currentUser, achievements: loadedAchievements, error: nil as Error?)
        }
      } catch {
        return (user: nil as User?, achievements: [] as [Achievement], error: error)
      }
    }.value
    
    // Update properties on main actor
    user = result.user
    achievements = result.achievements
    error = result.error
    isLoading = false
    statsPrimed = (result.user != nil)

    // Warm recent activity from cache immediately (no network) and optionally refresh
    await loadRecentFromCache()
  }

  /// Loads recent activity for the profile from cached MRU IDs and DB tasting cache
  func loadRecentFromCache(limit: Int = 10) async -> [TastingFeedItem] {
    guard let id = user?.id ?? userId else { return [] }
    let ids = await SnapshotStore.getUserRecent(userId: id, limit: limit)
    if ids.isEmpty { return [] }
    var items: [TastingFeedItem] = []
    for tid in ids {
      if let cached = try? await DatabaseManager.shared.getCachedTasting(id: tid) {
        items.append(cached.tasting)
      }
    }
    return items
  }

  private func applySnapshot(_ snap: UserProfileSnapshot) {
    var u = self.user ?? User(id: snap.id, email: "", username: snap.username ?? "")
    if let v = snap.username { u = User(id: u.id, email: u.email, username: v, verified: u.verified, admin: u.admin, mod: u.mod) }
    if let v = snap.pictureUrl { u.pictureUrl = v }
    if let v = snap.tastingsCount { u.tastingsCount = v }
    if let v = snap.bottlesCount { u.bottlesCount = v }
    if let v = snap.collectedCount { u.collectedCount = v }
    if let v = snap.contributionsCount { u.contributionsCount = v }
    if let v = snap.friendStatus { u.friendStatus = v }
    self.user = u
    self.statsPrimed = self.statsPrimed || (snap.tastingsCount != nil || snap.bottlesCount != nil || snap.collectedCount != nil || snap.contributionsCount != nil)
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
    let userKey: String
    if let targetId = self.userId ?? self.user?.id {
      userKey = targetId
    } else {
      userKey = "me"
    }

    do {
      if let favId = try await collectionRepository.getFavoritesCollectionId(user: userKey) {
        let items = try await collectionRepository.listBottles(in: favId, user: userKey)
        self.favorites = items
      } else {
        self.favorites = []
      }
    } catch {
      self.favoritesError = error
    }
  }
}
