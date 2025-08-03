import Foundation
import SQLite

/// Main database manager for Peated using SQLite.swift
public final class DatabaseManager: @unchecked Sendable {
  public static let shared = DatabaseManager()
  
  private let db: Connection
  private let databasePath: String
  
  private init() {
    do {
      // Get documents directory for database file
      let documentsPath = NSSearchPathForDirectoriesInDomains(
        .documentDirectory,
        .userDomainMask,
        true
      ).first!
      
      databasePath = "\(documentsPath)/peated.sqlite3"
      db = try Connection(databasePath)
      
      // Enable foreign keys
      try db.execute("PRAGMA foreign_keys = ON")
      
      // Run migrations on init
      try runMigrations()
    } catch {
      fatalError("Failed to initialize database: \(error)")
    }
  }
  
  /// Get database connection for direct access
  public var connection: Connection {
    db
  }
  
  /// Run all database migrations
  private func runMigrations() throws {
    let currentVersion = try getCurrentSchemaVersion()
    
    if currentVersion < 1 {
      try createInitialTables()
      try setSchemaVersion(1)
    }
    
    if currentVersion < 2 {
      try addOfflineOperationsTables()
      try setSchemaVersion(2)
    }
    
    // Add future migrations here
  }
  
  /// Get current schema version
  private func getCurrentSchemaVersion() throws -> Int {
    let versionTable = Table("schema_version")
    let version = Expression<Int>("version")
    
    // Check if schema_version table exists
    let tableExists = try db.scalar(
      "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='schema_version'"
    ) as! Int64
    
    if tableExists == 0 {
      // Create schema version table
      try db.run(versionTable.create { t in
        t.column(version, primaryKey: true)
      })
      try db.run(versionTable.insert(version <- 0))
      return 0
    }
    
    return try db.scalar(versionTable.select(version.max)) ?? 0
  }
  
  /// Set schema version
  private func setSchemaVersion(_ newVersion: Int) throws {
    let versionTable = Table("schema_version")
    let version = Expression<Int>("version")
    
    try db.run(versionTable.update(version <- newVersion))
  }
  
  /// Create initial database tables
  private func createInitialTables() throws {
    // Users table (for caching user data)
    try db.run(Tables.users.create(ifNotExists: true) { t in
      t.column(Tables.Users.id, primaryKey: true)
      t.column(Tables.Users.email)
      t.column(Tables.Users.username)
      t.column(Tables.Users.displayName)
      t.column(Tables.Users.pictureUrl)
      t.column(Tables.Users.createdAt)
      t.column(Tables.Users.updatedAt)
    })
    
    // Bottles table
    try db.run(Tables.bottles.create(ifNotExists: true) { t in
      t.column(Tables.Bottles.id, primaryKey: true)
      t.column(Tables.Bottles.name)
      t.column(Tables.Bottles.brand)
      t.column(Tables.Bottles.distillery)
      t.column(Tables.Bottles.category)
      t.column(Tables.Bottles.statedAge)
      t.column(Tables.Bottles.caskStrength)
      t.column(Tables.Bottles.singleCask)
      t.column(Tables.Bottles.createdAt)
      t.column(Tables.Bottles.updatedAt)
    })
    
    // Tastings table
    try db.run(Tables.tastings.create(ifNotExists: true) { t in
      t.column(Tables.Tastings.id, primaryKey: true)
      t.column(Tables.Tastings.bottleId)
      t.column(Tables.Tastings.userId)
      t.column(Tables.Tastings.rating)
      t.column(Tables.Tastings.notes)
      t.column(Tables.Tastings.tags)
      t.column(Tables.Tastings.servingStyle)
      t.column(Tables.Tastings.location)
      t.column(Tables.Tastings.isPublic)
      t.column(Tables.Tastings.createdAt)
      t.column(Tables.Tastings.updatedAt)
      t.column(Tables.Tastings.syncedAt)
      
      t.foreignKey(Tables.Tastings.bottleId, references: Tables.bottles, Tables.Bottles.id)
      t.foreignKey(Tables.Tastings.userId, references: Tables.users, Tables.Users.id)
    })
    
    // Collection table (user's bottle collection)
    try db.run(Tables.collection.create(ifNotExists: true) { t in
      t.column(Tables.Collection.id, primaryKey: true)
      t.column(Tables.Collection.userId)
      t.column(Tables.Collection.bottleId)
      t.column(Tables.Collection.status) // owned, wishlist, tried
      t.column(Tables.Collection.notes)
      t.column(Tables.Collection.createdAt)
      t.column(Tables.Collection.updatedAt)
      
      t.foreignKey(Tables.Collection.bottleId, references: Tables.bottles, Tables.Bottles.id)
      t.foreignKey(Tables.Collection.userId, references: Tables.users, Tables.Users.id)
      t.unique(Tables.Collection.userId, Tables.Collection.bottleId)
    })
  }
  
  /// Add offline operations tables
  private func addOfflineOperationsTables() throws {
    // Offline operations table
    try db.run(Tables.offlineOperations.create(ifNotExists: true) { t in
      t.column(Tables.OfflineOperations.id, primaryKey: true)
      t.column(Tables.OfflineOperations.type)
      t.column(Tables.OfflineOperations.payload)
      t.column(Tables.OfflineOperations.createdAt)
      t.column(Tables.OfflineOperations.retryCount)
      t.column(Tables.OfflineOperations.lastAttemptAt)
      t.column(Tables.OfflineOperations.status)
      t.column(Tables.OfflineOperations.lastError)
    })
    
    // Create index on status for faster queries
    try db.run(Tables.offlineOperations.createIndex(
      Tables.OfflineOperations.status,
      ifNotExists: true
    ))
  }
}

// MARK: - Table Definitions

public struct Tables {
  // Users table
  nonisolated(unsafe) public static let users = Table("users")
  public struct Users {
    nonisolated(unsafe) static let id = Expression<Int64>("id")
    nonisolated(unsafe) static let email = Expression<String?>("email")
    nonisolated(unsafe) static let username = Expression<String>("username")
    nonisolated(unsafe) static let displayName = Expression<String?>("display_name")
    nonisolated(unsafe) static let pictureUrl = Expression<String?>("picture_url")
    nonisolated(unsafe) static let createdAt = Expression<Date>("created_at")
    nonisolated(unsafe) static let updatedAt = Expression<Date>("updated_at")
  }
  
  // Bottles table
  nonisolated(unsafe) public static let bottles = Table("bottles")
  public struct Bottles {
    nonisolated(unsafe) static let id = Expression<Int64>("id")
    nonisolated(unsafe) static let name = Expression<String>("name")
    nonisolated(unsafe) static let brand = Expression<String?>("brand")
    nonisolated(unsafe) static let distillery = Expression<String?>("distillery")
    nonisolated(unsafe) static let category = Expression<String?>("category")
    nonisolated(unsafe) static let statedAge = Expression<Int?>("stated_age")
    nonisolated(unsafe) static let caskStrength = Expression<Bool>("cask_strength")
    nonisolated(unsafe) static let singleCask = Expression<Bool>("single_cask")
    nonisolated(unsafe) static let createdAt = Expression<Date>("created_at")
    nonisolated(unsafe) static let updatedAt = Expression<Date>("updated_at")
  }
  
  // Tastings table
  nonisolated(unsafe) public static let tastings = Table("tastings")
  public struct Tastings {
    nonisolated(unsafe) static let id = Expression<Int64>("id")
    nonisolated(unsafe) static let bottleId = Expression<Int64>("bottle_id")
    nonisolated(unsafe) static let userId = Expression<Int64>("user_id")
    nonisolated(unsafe) static let rating = Expression<Double?>("rating")
    nonisolated(unsafe) static let notes = Expression<String?>("notes")
    nonisolated(unsafe) static let tags = Expression<String?>("tags") // JSON array
    nonisolated(unsafe) static let servingStyle = Expression<String?>("serving_style")
    nonisolated(unsafe) static let location = Expression<String?>("location")
    nonisolated(unsafe) static let isPublic = Expression<Bool>("is_public")
    nonisolated(unsafe) static let createdAt = Expression<Date>("created_at")
    nonisolated(unsafe) static let updatedAt = Expression<Date>("updated_at")
    nonisolated(unsafe) static let syncedAt = Expression<Date?>("synced_at")
  }
  
  // Collection table
  nonisolated(unsafe) public static let collection = Table("collection")
  public struct Collection {
    nonisolated(unsafe) static let id = Expression<Int64>("id")
    nonisolated(unsafe) static let userId = Expression<Int64>("user_id")
    nonisolated(unsafe) static let bottleId = Expression<Int64>("bottle_id")
    nonisolated(unsafe) static let status = Expression<String>("status") // owned, wishlist, tried
    nonisolated(unsafe) static let notes = Expression<String?>("notes")
    nonisolated(unsafe) static let createdAt = Expression<Date>("created_at")
    nonisolated(unsafe) static let updatedAt = Expression<Date>("updated_at")
  }
  
  // Offline operations table
  nonisolated(unsafe) public static let offlineOperations = Table("offline_operations")
  public struct OfflineOperations {
    nonisolated(unsafe) static let id = Expression<String>("id")
    nonisolated(unsafe) static let type = Expression<String>("type")
    nonisolated(unsafe) static let payload = Expression<Data>("payload")
    nonisolated(unsafe) static let createdAt = Expression<Date>("created_at")
    nonisolated(unsafe) static let retryCount = Expression<Int>("retry_count")
    nonisolated(unsafe) static let lastAttemptAt = Expression<Date?>("last_attempt_at")
    nonisolated(unsafe) static let status = Expression<String>("status")
    nonisolated(unsafe) static let lastError = Expression<String?>("last_error")
  }
}