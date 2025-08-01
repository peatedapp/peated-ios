import SwiftUI
import PeatedCore
import Observation
import Combine

@Observable
class AppModel {
    var authState: AuthState = .unknown
    let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    var isLoading: Bool {
        authState == .unknown
    }
    
    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }
    
    init() {
        // Observe auth state changes
        authManager.$authState
            .sink { [weak self] peatedAuthState in
                guard let self = self else { return }
                self.authState = peatedAuthState
            }
            .store(in: &cancellables)
    }
    
    func checkAuthStatus() async {
        // Wait for auth check to complete
        await authManager.checkAuthStatus()
    }
    
    func handleAuthStateChanged(_ newState: AuthState) {
        print("AppModel: Updating auth state to: \(newState)")
        authState = newState
    }
}