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
  
  // Optional userId - if nil, shows current user
  let userId: String?
  private let seed: User?
  
  private let authManager = AuthenticationManager.shared
  private let achievementsRepository: AchievementsRepository
  private let userRepository: UserRepository
  
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

    // Start with seed or current user, but don't prime UI until we attempt a cache merge
    if let seed { self.user = seed }
    if userId == nil, let current = authManager.currentUser { if self.user == nil { self.user = current } }

    // Attempt cache merge before rendering anything to avoid defaults
    Task { [weak self] in
      guard let self else { return }
      let id = self.userId ?? self.user?.id ?? self.authManager.currentUser?.id
      if let id,
         let (cached, _) = await NormalizedStore.shared.get(.user(id), as: User.self) {
        self.user = self.mergedUser(self.user, with: cached)
        self.statsPrimed = true
      } else if self.user != nil {
        // We at least have seed/current; show that while network populates stats
      }
      self.isPrimed = (self.user != nil)
    }
  }
  
  func loadUser() async {
    isLoading = true
    error = nil
    // If not primed yet (e.g., no seed), try cache now; otherwise skip (already merged)
    if !isPrimed {
      if let id = userId ?? AuthenticationManager.shared.currentUser?.id,
         let (cached, _) = await NormalizedStore.shared.get(.user(id), as: User.self) {
        self.user = self.mergedUser(self.user, with: cached)
        self.statsPrimed = true
      }
      isPrimed = (self.user != nil)
    }
    
    // Use detached task to prevent cancellation
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
}
