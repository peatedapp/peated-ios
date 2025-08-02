import Foundation
import PeatedAPI

/// Protocol for repositories with common API client functionality
public protocol BaseRepositoryProtocol {
  var apiClient: APIClient { get }
}

/// Extension providing default implementation
public extension BaseRepositoryProtocol {
  /// Get the generated API client with middleware already configured
  var client: Client {
    get async {
      await apiClient.generatedClient
    }
  }
}

/// Protocol for repositories that support CRUD operations
public protocol CRUDRepository {
  associatedtype Entity
  associatedtype CreateInput
  associatedtype UpdateInput
  
  func create(_ input: CreateInput) async throws -> Entity
  func get(id: String) async throws -> Entity
  func update(id: String, input: UpdateInput) async throws -> Entity
  func delete(id: String) async throws
}

/// Protocol for repositories that support listing
public protocol ListRepository {
  associatedtype Entity
  associatedtype ListQuery
  
  func list(query: ListQuery) async throws -> [Entity]
}