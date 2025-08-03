import SwiftUI
import PeatedCore
import Observation

@Observable
class ProfileModel {
  var user: User?
  var achievements: [Achievement] = []
  var isLoading = false
  var error: Error?
  
  // Optional userId - if nil, shows current user
  let userId: String?
  
  private let authManager = AuthenticationManager.shared
  private let achievementsRepository: AchievementsRepository
  private let userRepository: UserRepository
  
  init(userId: String? = nil) {
    self.userId = userId
    
    // Create API client - using the same configuration as AuthenticationManager
    let apiClient = APIClient(
      serverURL: URL(string: "https://api.peated.com/v1")!
    )
    self.achievementsRepository = AchievementsRepository(apiClient: apiClient)
    self.userRepository = UserRepository(apiClient: apiClient)
  }
  
  func loadUser() async {
    isLoading = true
    error = nil
    
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
  }
  
  func logout() async {
    isLoading = true
    await authManager.logout()
    isLoading = false
    
    // The app will automatically navigate back to login
    // because AppView observes the auth state
  }
}