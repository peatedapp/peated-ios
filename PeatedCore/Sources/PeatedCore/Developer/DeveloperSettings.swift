import Foundation
import SwiftUI

@MainActor
public class DeveloperSettings: ObservableObject {
    public static let shared = DeveloperSettings()
    
    @AppStorage("dev.apiEnvironment") public var apiEnvironment: APIEnvironment = .production
    @AppStorage("dev.enableDebugLogging") public var enableDebugLogging: Bool = false
    @AppStorage("dev.enableNetworkInspector") public var enableNetworkInspector: Bool = false
    @AppStorage("dev.mockAPIResponses") public var mockAPIResponses: Bool = false
    @AppStorage("dev.showPerformanceOverlay") public var showPerformanceOverlay: Bool = false
    
    public var currentAPIURL: URL {
        switch apiEnvironment {
        case .production:
            return URL(string: "https://api.peated.com/v1")!
        case .local:
            return URL(string: "http://localhost:3000")!
        }
    }
    
    public func reset() {
        apiEnvironment = .production
        enableDebugLogging = false
        enableNetworkInspector = false
        mockAPIResponses = false
        showPerformanceOverlay = false
    }
}

public enum APIEnvironment: String, CaseIterable {
    case production = "Production"
    case local = "Local"
    
    public var icon: String {
        switch self {
        case .production: return "checkmark.shield.fill"
        case .local: return "laptopcomputer"
        }
    }
    
    public var color: Color {
        switch self {
        case .production: return .green
        case .local: return .orange
        }
    }
}