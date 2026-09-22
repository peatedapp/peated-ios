import Foundation
import GoogleSignIn
import PeatedCore
import SwiftUI

@main
struct PeatedApp: App {
    init() {
        #if DEBUG
            UITestHarness.installIfActive()
        #endif

        // Skip initialization when running tests
        guard !isRunningTests else { return }

        // Configure Google Sign-In on app launch
        setupGoogleSignIn()

        // Expand shared URL cache to better hold small images like avatars.
        // This complements our in-memory cache and lets the system reuse
        // images across sessions when server cache headers permit it.
        let memoryCapacity = 100 * 1024 * 1024 // 100 MB
        let diskCapacity = 500 * 1024 * 1024 // 500 MB
        if #available(iOS 13.0, *) {
            URLCache.shared = URLCache(memoryCapacity: memoryCapacity,
                                       diskCapacity: diskCapacity,
                                       directory: nil)
        } else {
            URLCache.shared = URLCache(memoryCapacity: memoryCapacity,
                                       diskCapacity: diskCapacity,
                                       diskPath: "com.peated.urlcache")
        }

        // Start error reporting before any repository or model can fail.
        SentryTelemetryReporter.start()
    }

    var body: some Scene {
        WindowGroup {
            AppView()
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

    /// Detect if we're running in a test environment
    private var isRunningTests: Bool {
        #if DEBUG
            if UITestHarness.isActive {
                return true
            }
        #endif
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
