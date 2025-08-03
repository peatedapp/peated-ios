import Foundation
import PeatedAPI
import HTTPTypes

/// Main API client for Peated
public actor APIClient {
    private let client: Client
    private let transport: URLSessionTransport
    
    public init(serverURL: URL, configuration: URLSessionTransport.Configuration = .init()) {
        self.transport = URLSessionTransport(configuration: configuration)
        
        // Configure date transcoding to handle various date formats
        let runtimeConfiguration = OpenAPIRuntime.Configuration(
            dateTranscoder: CustomDateTranscoder()
        )
        
        // Add middleware stack
        let authMiddleware = AuthMiddleware()
        let loggingMiddleware = LoggingMiddleware()
        
        self.client = Client(
            serverURL: serverURL,
            configuration: runtimeConfiguration,
            transport: transport,
            middlewares: [loggingMiddleware, authMiddleware]
        )
    }
    
    /// Get the underlying generated client for direct access
    public var generatedClient: Client {
        client
    }
    
    // Add convenience methods here as needed
}