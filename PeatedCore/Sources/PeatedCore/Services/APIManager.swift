import Foundation

/// Manager for API client that handles dynamic server URL changes
@MainActor
public class APIManager: ObservableObject {
    public static let shared = APIManager()

    @Published public private(set) var apiClient: APIClient

    private init() {
        let initialURL = DeveloperSettings.shared.currentAPIURL
        apiClient = APIClient(serverURL: initialURL)

        // Listen for API environment changes
        Task {
            await observeAPIEnvironmentChanges()
        }

        // Broadcast initial environment so other APIClient instances align on launch
        NotificationCenter.default.post(
            name: .apiEnvironmentDidChange,
            object: self,
            userInfo: ["url": initialURL]
        )
    }

    private func observeAPIEnvironmentChanges() async {
        // This would ideally use Combine but for simplicity we'll use a method
        // that can be called when settings change
    }

    /// Update the API client with a new server URL
    public func updateAPIClient(with url: URL) async {
        await apiClient.updateServerURL(url)
    }

    /// Refresh API client with current developer settings
    public func refreshFromSettings() async {
        let newURL = DeveloperSettings.shared.currentAPIURL
        await apiClient.updateServerURL(newURL)
        NotificationCenter.default.post(
            name: .apiEnvironmentDidChange,
            object: self,
            userInfo: ["url": newURL]
        )
    }
}
