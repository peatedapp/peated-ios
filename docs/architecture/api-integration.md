# API Integration

## Overview

Peated uses OpenAPI Generator to create a type-safe Swift client from the API specification. This ensures consistency between the backend and mobile app while reducing boilerplate code.

## OpenAPI Specification

The OpenAPI specification is publicly available at:
- **Production**: https://api.peated.com/spec.json

### Fetching the Spec

```bash
# Download the latest API specification
curl -o peated-api-spec.json https://api.peated.com/spec.json

# Pretty print for review (optional)
cat peated-api-spec.json | jq '.' > peated-api-spec-formatted.json
```

## OpenAPI Client Generation

### Setup

We use Apple's Swift OpenAPI Generator (not the Java-based openapi-generator):

```bash
# The generator is included as a package dependency
# No separate installation needed
```

### Updating API Bindings

To update the API client when the backend changes:

```bash
# 1. Download the latest OpenAPI spec
curl -o peated-api.json https://api.peated.com/spec.json

# 2. Generate the API client
swift run swift-openapi-generator generate \
  --config openapi-generator-config.yaml \
  --output-directory ./Sources/PeatedAPI \
  peated-api.json

# 3. Build to verify the changes compile
swift build
```

The configuration file `openapi-generator-config.yaml` should contain:
```yaml
generate:
  - types
  - client

accessModifier: internal
module: PeatedAPI
```

### Generated Structure

```
PeatedAPI/
├── Classes/
│   ├── OpenAPIs/
│   │   ├── APIs/
│   │   │   ├── AuthAPI.swift
│   │   │   ├── BottlesAPI.swift
│   │   │   ├── TastingsAPI.swift
│   │   │   └── UsersAPI.swift
│   │   ├── Models/
│   │   │   ├── AuthRequest.swift
│   │   │   ├── Bottle.swift
│   │   │   ├── Tasting.swift
│   │   │   └── User.swift
│   │   └── Configuration.swift
└── Package.swift
```

## Authentication

### Auth Flow

```swift
// Authentication Manager
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let keychain = KeychainService()
    private var apiClient: APIClient
    
    // MARK: - Email/Password Login
    func login(email: String, password: String) async throws {
        let request = AuthRequest(
            email: email,
            password: password
        )
        
        let response = try await AuthAPI.login(authRequest: request)
        
        // Store tokens
        try keychain.store(response.accessToken, for: .accessToken)
        try keychain.store(response.refreshToken, for: .refreshToken)
        
        // Configure API client
        configureAPIClient(with: response.accessToken)
        
        // Fetch current user
        currentUser = try await UsersAPI.getCurrentUser()
        isAuthenticated = true
    }
    
    // MARK: - Google OAuth
    func loginWithGoogle(authCode: String) async throws {
        let request = AuthRequest(code: authCode)
        
        let response = try await AuthAPI.loginWithGoogle(authRequest: request)
        
        // Same token storage as email/password
        try keychain.store(response.accessToken, for: .accessToken)
        try keychain.store(response.refreshToken, for: .refreshToken)
        
        configureAPIClient(with: response.accessToken)
        currentUser = try await UsersAPI.getCurrentUser()
        isAuthenticated = true
    }
    
    // MARK: - Token Refresh
    func refreshTokenIfNeeded() async throws {
        guard let refreshToken = try? keychain.retrieve(.refreshToken) else {
            throw AuthError.notAuthenticated
        }
        
        let response = try await AuthAPI.refreshToken(
            refreshRequest: RefreshRequest(refreshToken: refreshToken)
        )
        
        try keychain.store(response.accessToken, for: .accessToken)
        configureAPIClient(with: response.accessToken)
    }
    
    // MARK: - API Configuration
    private func configureAPIClient(with token: String) {
        OpenAPIClientAPI.customHeaders = [
            "Authorization": "Bearer \(token)"
        ]
    }
}
```

### Keychain Storage

```swift
enum KeychainKey: String {
    case accessToken = "com.peated.accessToken"
    case refreshToken = "com.peated.refreshToken"
    case userId = "com.peated.userId"
}

class KeychainService {
    func store(_ value: String, for key: KeychainKey) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore
        }
    }
    
    func retrieve(_ key: KeychainKey) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.itemNotFound
        }
        
        return value
    }
}
```

## API Client Configuration

### Custom URL Session

```swift
extension OpenAPIClientAPI {
    static func configureURLSession() {
        let configuration = URLSessionConfiguration.default
        
        // Timeouts
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        
        // Caching
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024, // 10 MB
            diskCapacity: 50 * 1024 * 1024,    // 50 MB
            diskPath: "com.peated.urlcache"
        )
        
        // Background support
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        configuration.shouldUseExtendedBackgroundIdleMode = true
        
        urlSession = URLSession(configuration: configuration)
    }
}
```

### Request Interceptor

```swift
class APIRequestInterceptor: RequestInterceptor {
    let authManager: AuthManager
    
    func adapt(_ urlRequest: URLRequest) async throws -> URLRequest {
        var request = urlRequest
        
        // Add custom headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("iOS/\(Bundle.main.appVersion)", forHTTPHeaderField: "User-Agent")
        
        // Add auth token if available
        if let token = try? KeychainService().retrieve(.accessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    func retry(_ request: URLRequest, for error: Error) async throws -> Bool {
        // Check if error is 401 Unauthorized
        if let httpResponse = (error as? URLError)?.userInfo[NSURLSessionDownloadTaskResumeData] as? HTTPURLResponse,
           httpResponse.statusCode == 401 {
            
            // Try to refresh token
            do {
                try await authManager.refreshTokenIfNeeded()
                return true // Retry the request
            } catch {
                // Refresh failed, log out user
                await authManager.logout()
                return false
            }
        }
        
        return false
    }
}
```

## API Usage Examples

### Fetching Data

```swift
// Repository implementation
class FeedRepository {
    private let apiClient = TastingsAPI()
    private let modelContext: ModelContext
    
    func getFeed(type: FeedType, cursor: String? = nil) async throws -> FeedPage {
        // API call
        let response = try await TastingsAPI.getFeed(
            feedType: type.rawValue,
            cursor: cursor,
            limit: 20
        )
        
        // Transform and save to SwiftData
        let tastings = response.tastings.map { apiTasting in
            // Find or create local model
            let predicate = #Predicate<Tasting> { $0.id == apiTasting.id }
            let descriptor = FetchDescriptor(predicate: predicate)
            
            if let existing = try? modelContext.fetch(descriptor).first {
                // Update existing
                existing.update(from: apiTasting)
                return existing
            } else {
                // Create new
                return Tasting(from: apiTasting)
            }
        }
        
        // Save context
        try modelContext.save()
        
        return FeedPage(
            tastings: tastings,
            cursor: response.cursor,
            hasMore: response.hasMore
        )
    }
}
```

### Creating Data

```swift
class TastingRepository {
    func createTasting(_ input: CreateTastingInput) async throws -> Tasting {
        // Create local model first (optimistic update)
        let localTasting = Tasting(
            id: UUID().uuidString,
            rating: input.rating,
            notes: input.notes,
            bottle: input.bottle,
            user: currentUser
        )
        localTasting.syncStatus = .pending
        
        modelContext.insert(localTasting)
        try modelContext.save()
        
        // Queue for API sync
        let mutation = PendingMutation(
            type: .createTasting,
            entityId: localTasting.id,
            payload: try JSONEncoder().encode(input)
        )
        modelContext.insert(mutation)
        
        // Attempt immediate sync
        Task {
            do {
                let request = CreateTastingRequest(
                    bottleId: input.bottle.id,
                    rating: input.rating,
                    notes: input.notes,
                    tags: input.tags,
                    servingStyle: input.servingStyle?.rawValue,
                    locationId: input.location?.id,
                    imageIds: input.uploadedImageIds
                )
                
                let response = try await TastingsAPI.createTasting(request)
                
                // Update local model with server response
                localTasting.id = response.id
                localTasting.syncStatus = .synced
                localTasting.update(from: response)
                
                // Remove pending mutation
                modelContext.delete(mutation)
                try modelContext.save()
            } catch {
                // Will retry later via sync service
                localTasting.syncStatus = .failed
                mutation.error = error.localizedDescription
                mutation.lastAttemptAt = Date()
            }
        }
        
        return localTasting
    }
}
```

### Image Upload

```swift
extension ImagesAPI {
    static func uploadTastingImages(_ images: [UIImage]) async throws -> [String] {
        var uploadedIds: [String] = []
        
        for image in images {
            // Compress image
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                continue
            }
            
            // Create multipart request
            let response = try await uploadImage(
                imageData: imageData,
                filename: "tasting_\(Date().timeIntervalSince1970).jpg",
                mimeType: "image/jpeg"
            )
            
            uploadedIds.append(response.id)
        }
        
        return uploadedIds
    }
}
```

## Error Handling

```swift
enum APIError: LocalizedError {
    case unauthorized
    case networkError(Error)
    case serverError(Int, String?)
    case decodingError(Error)
    case validationError([String: String])
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please log in to continue"
        case .networkError:
            return "Network connection error. Please try again."
        case .serverError(let code, let message):
            return message ?? "Server error (\(code))"
        case .decodingError:
            return "Unable to process server response"
        case .validationError(let errors):
            return errors.values.joined(separator: "\n")
        }
    }
}

// Usage in API calls
extension APIClient {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        do {
            let (data, response) = try await urlSession.data(for: endpoint.urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(URLError(.badServerResponse))
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(T.self, from: data)
            case 401:
                throw APIError.unauthorized
            case 422:
                let errors = try JSONDecoder().decode([String: String].self, from: data)
                throw APIError.validationError(errors)
            default:
                let message = try? JSONDecoder().decode(ErrorResponse.self, from: data).message
                throw APIError.serverError(httpResponse.statusCode, message)
            }
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}
```

## Offline Queue Processing

```swift
actor SyncService {
    private let modelContext: ModelContext
    private var syncTimer: Timer?
    
    func startSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await self.processPendingMutations()
            }
        }
        
        // Also sync on network change
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged),
            name: .reachabilityChanged,
            object: nil
        )
    }
    
    func processPendingMutations() async {
        let descriptor = FetchDescriptor<PendingMutation>(
            predicate: #Predicate { $0.retryCount < $0.maxRetries },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        guard let mutations = try? modelContext.fetch(descriptor),
              !mutations.isEmpty else { return }
        
        for mutation in mutations {
            do {
                try await processMutation(mutation)
                modelContext.delete(mutation)
            } catch {
                mutation.retryCount += 1
                mutation.lastAttemptAt = Date()
                mutation.error = error.localizedDescription
                
                if mutation.retryCount >= mutation.maxRetries {
                    // Notify user of permanent failure
                    NotificationCenter.default.post(
                        name: .syncFailed,
                        object: mutation
                    )
                }
            }
        }
        
        try? modelContext.save()
    }
    
    private func processMutation(_ mutation: PendingMutation) async throws {
        switch mutation.type {
        case .createTasting:
            let input = try JSONDecoder().decode(CreateTastingInput.self, from: mutation.payload)
            _ = try await TastingsAPI.createTasting(input.toRequest())
            
        case .createToast:
            try await ToastsAPI.createToast(tastingId: mutation.entityId)
            
        case .deleteToast:
            try await ToastsAPI.deleteToast(tastingId: mutation.entityId)
            
        // ... other mutation types
        }
    }
}
```