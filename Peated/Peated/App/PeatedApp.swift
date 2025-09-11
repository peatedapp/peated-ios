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
        // Prefer explicit configuration to avoid plist drift
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
           !clientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }
}
