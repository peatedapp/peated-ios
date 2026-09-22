import Foundation
import HTTPTypes
import OpenAPIRuntime
import PeatedAPI

/// Main API client for Peated
public actor APIClient {
    /// Shared singleton instance
    public static let shared = APIClient()

    /// Replaces the network for every client created after it is set.
    ///
    /// Set it once, before the first `APIClient` exists. The debug UI-test
    /// harness uses it to answer requests from canned responses. Production
    /// code never sets it.
    public nonisolated(unsafe) static var launchTransport: (any ClientTransport)?

    private var client: Client
    private let transport: any ClientTransport
    private var currentServerURL: URL

    public init(serverURL: URL? = nil, transport: (any ClientTransport)? = nil) {
        // Use provided URL or default production
        currentServerURL = serverURL ?? URL(string: "https://api.peated.com/v1")!

        self.transport = transport ?? Self.launchTransport ?? URLSessionTransport()

        client = Self.makeClient(serverURL: currentServerURL, transport: self.transport)

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
        client = Self.makeClient(serverURL: url, transport: transport)
    }

    /// Get the underlying generated client for direct access
    public var generatedClient: Client {
        client
    }

    private static func makeClient(serverURL: URL, transport: any ClientTransport) -> Client {
        // Configure date transcoding to handle various date formats
        let runtimeConfiguration = OpenAPIRuntime.Configuration(
            dateTranscoder: CustomDateTranscoder()
        )

        return Client(
            serverURL: serverURL,
            configuration: runtimeConfiguration,
            transport: transport,
            middlewares: [
                LoggingMiddleware(),
                CacheConditionalsMiddleware(),
                AuthMiddleware()
            ]
        )
    }
}
