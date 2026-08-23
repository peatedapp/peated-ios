import Foundation
import HTTPTypes
import PeatedAPI

/// Main API client for Peated
public actor APIClient {
    /// Shared singleton instance
    public static let shared = APIClient()

    private var client: Client
    private let transport: URLSessionTransport
    private var currentServerURL: URL

    public init(serverURL: URL? = nil, configuration: URLSessionTransport.Configuration = .init()) {
        // Use provided URL or default production
        currentServerURL = serverURL ?? URL(string: "https://api.peated.com/v1")!

        transport = URLSessionTransport(configuration: configuration)

        // Configure date transcoding to handle various date formats
        let runtimeConfiguration = OpenAPIRuntime.Configuration(
            dateTranscoder: CustomDateTranscoder()
        )

        // Add middleware stack
        let authMiddleware = AuthMiddleware()
        let loggingMiddleware = LoggingMiddleware()
        let cacheConditionals = CacheConditionalsMiddleware()
        let bottlePhotoUploadMiddleware = BottlePhotoUploadMiddleware()

        client = Client(
            serverURL: currentServerURL,
            configuration: runtimeConfiguration,
            transport: transport,
            middlewares: [
                bottlePhotoUploadMiddleware,
                loggingMiddleware,
                cacheConditionals,
                authMiddleware
            ]
        )

        // Observe environment changes and update server URL for all instances
        Task { [currentURL = currentServerURL] in
            // Start by ensuring we match the latest selected environment if provided later
            for await note in NotificationCenter.default.notifications(named: .apiEnvironmentDidChange) {
                if let url = note.userInfo?["url"] as? URL {
                    await self.updateServerURL(url)
                }
            }
            _ = currentURL // silence capture warning
        }
    }

    /// Update the server URL dynamically
    public func updateServerURL(_ url: URL) {
        guard url != currentServerURL else { return }

        currentServerURL = url

        let runtimeConfiguration = OpenAPIRuntime.Configuration(
            dateTranscoder: CustomDateTranscoder()
        )

        let authMiddleware = AuthMiddleware()
        let loggingMiddleware = LoggingMiddleware()
        let cacheConditionals = CacheConditionalsMiddleware()
        let bottlePhotoUploadMiddleware = BottlePhotoUploadMiddleware()

        client = Client(
            serverURL: url,
            configuration: runtimeConfiguration,
            transport: transport,
            middlewares: [
                bottlePhotoUploadMiddleware,
                loggingMiddleware,
                cacheConditionals,
                authMiddleware
            ]
        )
    }

    /// Get the underlying generated client for direct access
    public var generatedClient: Client {
        client
    }

    // Add convenience methods here as needed
}
