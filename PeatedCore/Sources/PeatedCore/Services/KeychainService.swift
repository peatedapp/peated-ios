import Foundation
import Security

public enum KeychainError: Error {
  case itemNotFound
  case unexpectedData
  case unhandledError(status: OSStatus)
}

public final class KeychainService: @unchecked Sendable {
  public static let shared = KeychainService()
  
  private let service = "com.peated.peated-ios"
  private let tokenKey = "auth_token"
  private let refreshTokenKey = "refresh_token"
  
  private init() {}
  
  public func saveToken(_ token: String) throws {
    let data = token.data(using: .utf8)!
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: tokenKey,
      kSecValueData as String: data
    ]
    
    // Try to delete any existing item first
    SecItemDelete(query as CFDictionary)
    
    // Add the new item
    let status = SecItemAdd(query as CFDictionary, nil)
    
    guard status == errSecSuccess else {
      throw KeychainError.unhandledError(status: status)
    }
  }
  
  public func getToken() throws -> String {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: tokenKey,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
    
    guard status == errSecSuccess else {
      if status == errSecItemNotFound {
        throw KeychainError.itemNotFound
      }
      throw KeychainError.unhandledError(status: status)
    }
    
    guard let data = dataTypeRef as? Data,
          let token = String(data: data, encoding: .utf8) else {
      throw KeychainError.unexpectedData
    }
    
    return token
  }
  
  public func deleteToken() throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: tokenKey
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.unhandledError(status: status)
    }
  }
  
  public var hasToken: Bool {
    do {
      _ = try getToken()
      return true
    } catch {
      return false
    }
  }
  
  // MARK: - Refresh Token Methods
  
  public func saveRefreshToken(_ token: String) throws {
    let data = token.data(using: .utf8)!
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: refreshTokenKey,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    
    let status = SecItemAdd(query as CFDictionary, nil)
    
    if status == errSecDuplicateItem {
      // Update existing item
      let updateQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: refreshTokenKey
      ]
      
      let attributes: [String: Any] = [
        kSecValueData as String: data
      ]
      
      let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
      
      guard updateStatus == errSecSuccess else {
        throw KeychainError.unhandledError(status: updateStatus)
      }
    } else if status != errSecSuccess {
      throw KeychainError.unhandledError(status: status)
    }
  }
  
  public func getRefreshToken() throws -> String {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: refreshTokenKey,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
    
    guard status == errSecSuccess else {
      if status == errSecItemNotFound {
        throw KeychainError.itemNotFound
      }
      throw KeychainError.unhandledError(status: status)
    }
    
    guard let data = dataTypeRef as? Data,
          let token = String(data: data, encoding: .utf8) else {
      throw KeychainError.unexpectedData
    }
    
    return token
  }
  
  public func deleteRefreshToken() throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: refreshTokenKey
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.unhandledError(status: status)
    }
  }
}