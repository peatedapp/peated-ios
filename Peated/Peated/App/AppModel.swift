import Combine
import Observation
import PeatedCore
import SwiftUI

/// Root auth state for `AppView`.
///
/// `AuthenticationManager` publishes from whichever thread its async work
/// finishes on. SwiftUI must only see this model change on the main actor:
/// a write from another thread can land while `AppView.body` is being
/// tracked, and SwiftUI then never re-renders, leaving the launch splash up.
@MainActor
@Observable
class AppModel {
    var authState: AuthState = .unknown
    var needsTermsAcceptance: Bool = false
    let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()

    var isLoading: Bool {
        authState == .unknown
    }

    var isAuthenticated: Bool {
        if case .authenticated = authState {
            return true
        }
        return false
    }

    init() {
        // Observe auth state changes
        authManager.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] peatedAuthState in
                guard let self else { return }
                authState = peatedAuthState
            }
            .store(in: &cancellables)

        // Observe terms acceptance requirement
        authManager.$needsTermsAcceptance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] needsAcceptance in
                guard let self else { return }
                needsTermsAcceptance = needsAcceptance
            }
            .store(in: &cancellables)
    }

    func checkAuthStatus() async {
        await authManager.checkAuthStatus()
        // The sink delivers asynchronously; callers read the result right away.
        authState = authManager.authState
    }

    func handleAuthStateChanged(_ newState: AuthState) {
        print("AppModel: Updating auth state to: \(newState)")
        authState = newState
    }
}
