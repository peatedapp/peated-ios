import SwiftUI
import PeatedCore
import GoogleSignIn
import Foundation

@main
struct PeatedApp: App {
    init() {
        // Configure Google Sign-In on app launch
        setupGoogleSignIn()

        // Expand shared URL cache to better hold small images like avatars.
        // This complements our in-memory cache and lets the system reuse
        // images across sessions when server cache headers permit it.
        let memoryCapacity = 100 * 1024 * 1024 // 100 MB
        let diskCapacity = 500 * 1024 * 1024   // 500 MB
        if #available(iOS 13.0, *) {
            URLCache.shared = URLCache(memoryCapacity: memoryCapacity,
                                       diskCapacity: diskCapacity,
                                       directory: nil)
        } else {
            URLCache.shared = URLCache(memoryCapacity: memoryCapacity,
                                       diskCapacity: diskCapacity,
                                       diskPath: "com.peated.urlcache")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    // Google Sign-In handler
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
