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
  
  func loadUser() async {
    // Get the current user from auth manager
    user = authManager.currentUser
    
    // Mock some achievements for now (TODO: fetch from API when available)
    achievements = [
      Achievement(id: "1", name: "Single Malter", level: 11),
      Achievement(id: "2", name: "Bourbon Lover", level: 5),
      Achievement(id: "3", name: "Explorer", level: 3)
    ]
  }
  
  func logout() async {
    isLoading = true
    await authManager.logout()
    isLoading = false
    
    // The app will automatically navigate back to login
    // because AppView observes the auth state
  }
}