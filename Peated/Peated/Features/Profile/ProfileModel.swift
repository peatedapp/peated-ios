import SwiftUI
import PeatedCore
import Observation

@Observable
class ProfileModel {
  var user: User?
  var achievements: [Achievement] = []
  var isLoading = false
  var error: Error?
  
  private let authManager = AuthenticationManager.shared
  private let achievementsRepository: AchievementsRepository
  
  init() {
    // Create API client - using the same configuration as AuthenticationManager
    let apiClient = APIClient(
      serverURL: URL(string: "https://api.peated.com/v1")!
    )
    self.achievementsRepository = AchievementsRepository(apiClient: apiClient)
  }
  
  func loadUser() async {
    // Get the current user from auth manager
    user = authManager.currentUser
    
    // Load achievements from API
    isLoading = true
    error = nil
    
    do {
      // Fetch real achievements from the API
      achievements = try await achievementsRepository.getCurrentUserBadges()
    } catch {
      self.error = error
      // Fallback to empty array on error
      achievements = []
      print("Failed to load achievements: \(error)")
    }
    
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