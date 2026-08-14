import Foundation
import SwiftUI

@MainActor
public class DeveloperSettings: ObservableObject {
    public static let shared = DeveloperSettings()

    @AppStorage("dev.apiEnvironment") public var apiEnvironment: APIEnvironment = .production
    // Placeholder flags removed: keep class minimal until tools exist

    public var currentAPIURL: URL {
        switch apiEnvironment {
        case .production:
            URL(string: "https://api.peated.com/v1")!
        case .local:
            URL(string: "http://localhost:3000")!
        }
    }

    public func reset() {
        apiEnvironment = .production
        // No extra flags to reset currently
    }
}

public enum APIEnvironment: String, CaseIterable {
    case production = "Production"
    case local = "Local"

    public var icon: String {
        switch self {
        case .production: "checkmark.shield.fill"
        case .local: "laptopcomputer"
        }
    }

    public var color: Color {
        switch self {
        case .production: .green
        case .local: .orange
        }
    }
}
