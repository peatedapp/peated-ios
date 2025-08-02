import Foundation
import SQLite

/// Represents a whisky bottle in the database
public struct DBBottle: Codable {
  public let id: Int64
  public let name: String
  public let brand: String?
  public let distillery: String?
  public let category: String?
  public let statedAge: Int?
  public let caskStrength: Bool
  public let singleCask: Bool
  public let createdAt: Date
  public let updatedAt: Date
  
  public init(
    id: Int64,
    name: String,
    brand: String? = nil,
    distillery: String? = nil,
    category: String? = nil,
    statedAge: Int? = nil,
    caskStrength: Bool = false,
    singleCask: Bool = false,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.name = name
    self.brand = brand
    self.distillery = distillery
    self.category = category
    self.statedAge = statedAge
    self.caskStrength = caskStrength
    self.singleCask = singleCask
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

// MARK: - Database Operations

extension DBBottle {
  /// Create from database row
  static func from(row: Row) throws -> DBBottle {
    DBBottle(
      id: try row.get(Tables.Bottles.id),
      name: try row.get(Tables.Bottles.name),
      brand: try row.get(Tables.Bottles.brand),
      distillery: try row.get(Tables.Bottles.distillery),
      category: try row.get(Tables.Bottles.category),
      statedAge: try row.get(Tables.Bottles.statedAge),
      caskStrength: try row.get(Tables.Bottles.caskStrength),
      singleCask: try row.get(Tables.Bottles.singleCask),
      createdAt: try row.get(Tables.Bottles.createdAt),
      updatedAt: try row.get(Tables.Bottles.updatedAt)
    )
  }
  
  /// Insert or update in database
  public func save(to db: Connection) throws {
    if try existsInDatabase(db) {
      try update(in: db)
    } else {
      try insert(into: db)
    }
  }
  
  /// Check if exists in database
  private func existsInDatabase(_ db: Connection) throws -> Bool {
    let count = try db.scalar(
      Tables.bottles
        .filter(Tables.Bottles.id == id)
        .count
    )
    return count > 0
  }
  
  /// Insert new bottle
  private func insert(into db: Connection) throws {
    try db.run(Tables.bottles.insert(
      Tables.Bottles.id <- id,
      Tables.Bottles.name <- name,
      Tables.Bottles.brand <- brand,
      Tables.Bottles.distillery <- distillery,
      Tables.Bottles.category <- category,
      Tables.Bottles.statedAge <- statedAge,
      Tables.Bottles.caskStrength <- caskStrength,
      Tables.Bottles.singleCask <- singleCask,
      Tables.Bottles.createdAt <- createdAt,
      Tables.Bottles.updatedAt <- Date()
    ))
  }
  
  /// Update existing bottle
  private func update(in db: Connection) throws {
    let bottle = Tables.bottles.filter(Tables.Bottles.id == id)
    try db.run(bottle.update(
      Tables.Bottles.name <- name,
      Tables.Bottles.brand <- brand,
      Tables.Bottles.distillery <- distillery,
      Tables.Bottles.category <- category,
      Tables.Bottles.statedAge <- statedAge,
      Tables.Bottles.caskStrength <- caskStrength,
      Tables.Bottles.singleCask <- singleCask,
      Tables.Bottles.updatedAt <- Date()
    ))
  }
  
  /// Find bottle by ID
  public static func find(_ id: Int64, in db: Connection) throws -> DBBottle? {
    let query = Tables.bottles.filter(Tables.Bottles.id == id)
    guard let row = try db.pluck(query) else { return nil }
    return try from(row: row)
  }
  
  /// Search bottles by name
  public static func search(name: String, in db: Connection) throws -> [DBBottle] {
    let query = Tables.bottles
      .filter(Tables.Bottles.name.like("%\(name)%"))
      .order(Tables.Bottles.name.asc)
      .limit(50)
    
    return try db.prepare(query).map { try from(row: $0) }
  }
}