import SwiftUI
import Sentry

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

        // Initialize Sentry
        SentrySDK.start { options in
            options.dsn = "https://768306340a5c4721d816c33502f7e06e@o4505211758706688.ingest.us.sentry.io/4510132027457536"
            options.debug = true // Enabled debug when first installing is always helpful

            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
                $0.lifecycle = .trace
            }

            // Uncomment the following lines to add more data to your events
            // options.attachScreenshot = true // This adds a screenshot to the error events
            // options.attachViewHierarchy = true // This adds the view hierarchy to the error events

            // Enable experimental logging features
            options.experimental.enableLogs = true
        }
        // Remove the next line after confirming that your Sentry integration is working.
        SentrySDK.capture(message: "This app uses Sentry! :)")
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
