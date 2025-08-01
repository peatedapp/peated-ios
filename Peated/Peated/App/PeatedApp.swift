import SwiftUI
import PeatedCore
import GoogleSignIn

@main
struct PeatedApp: App {
    init() {
        // Configure Google Sign-In on app launch
        setupGoogleSignIn()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
    
    private func setupGoogleSignIn() {
        // Google Sign-In is configured in Info.plist
        // No additional setup needed here
    }
}