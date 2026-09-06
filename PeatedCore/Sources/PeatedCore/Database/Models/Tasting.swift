import Foundation
import SQLite

/// Represents a whisky tasting/check-in
public struct Tasting: Codable {
    public let id: Int64
    public let bottleId: Int64
    public let userId: Int64
    public let ratingBand: TastingRatingBand?
    public let notes: String?
    public let tags: [String]
    public let servingStyle: String?
    public let location: String?
    public let isPublic: Bool
    public let createdAt: Date
    public let updatedAt: Date
    public let syncedAt: Date?

    public init(
        id: Int64,
        bottleId: Int64,
        userId: Int64,
        ratingBand: TastingRatingBand? = nil,
        notes: String? = nil,
        tags: [String] = [],
        servingStyle: String? = nil,
        location: String? = nil,
        isPublic: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncedAt: Date? = nil
    ) {
        self.id = id
        self.bottleId = bottleId
        self.userId = userId
        self.ratingBand = ratingBand
        self.notes = notes
        self.tags = tags
        self.servingStyle = servingStyle
        self.location = location
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncedAt = syncedAt
    }
}

// MARK: - Database Operations

public extension Tasting {
    /// Create from database row
    internal static func from(row: Row) throws -> Tasting {
        let tagsJson = try row.get(Tables.Tastings.tags) ?? "[]"
        let tags = try JSONDecoder().decode([String].self, from: tagsJson.data(using: .utf8)!)

        return try Tasting(
            id: row.get(Tables.Tastings.id),
            bottleId: row.get(Tables.Tastings.bottleId),
            userId: row.get(Tables.Tastings.userId),
            ratingBand: row.get(Tables.Tastings.ratingBand).flatMap(TastingRatingBand.init(rawValue:)),
            notes: row.get(Tables.Tastings.notes),
            tags: tags,
            servingStyle: row.get(Tables.Tastings.servingStyle),
            location: row.get(Tables.Tastings.location),
            isPublic: row.get(Tables.Tastings.isPublic),
            createdAt: row.get(Tables.Tastings.createdAt),
            updatedAt: row.get(Tables.Tastings.updatedAt),
            syncedAt: row.get(Tables.Tastings.syncedAt)
        )
    }

    /// Save to database
    func save(to db: Connection) throws {
        let tagsJson = try JSONEncoder().encode(tags)
        let tagsString = String(data: tagsJson, encoding: .utf8)!

        if try existsInDatabase(db) {
            try update(in: db, tagsJson: tagsString)
        } else {
            try insert(into: db, tagsJson: tagsString)
        }
    }

    /// Check if exists in database
    private func existsInDatabase(_ db: Connection) throws -> Bool {
        let count = try db.scalar(
            Tables.tastings
                .filter(Tables.Tastings.id == id)
                .count
        )
        return count > 0
    }

    /// Insert new tasting
    private func insert(into db: Connection, tagsJson: String) throws {
        try db.run(Tables.tastings.insert(
            Tables.Tastings.id <- id,
            Tables.Tastings.bottleId <- bottleId,
            Tables.Tastings.userId <- userId,
            Tables.Tastings.ratingBand <- ratingBand?.rawValue,
            Tables.Tastings.notes <- notes,
            Tables.Tastings.tags <- tagsJson,
            Tables.Tastings.servingStyle <- servingStyle,
            Tables.Tastings.location <- location,
            Tables.Tastings.isPublic <- isPublic,
            Tables.Tastings.createdAt <- createdAt,
            Tables.Tastings.updatedAt <- Date(),
            Tables.Tastings.syncedAt <- syncedAt
        ))
    }

    /// Update existing tasting
    private func update(in db: Connection, tagsJson: String) throws {
        let tasting = Tables.tastings.filter(Tables.Tastings.id == id)
        try db.run(tasting.update(
            Tables.Tastings.ratingBand <- ratingBand?.rawValue,
            Tables.Tastings.notes <- notes,
            Tables.Tastings.tags <- tagsJson,
            Tables.Tastings.servingStyle <- servingStyle,
            Tables.Tastings.location <- location,
            Tables.Tastings.isPublic <- isPublic,
            Tables.Tastings.updatedAt <- Date()
        ))
    }

    /// Find tasting by ID
    static func find(_ id: Int64, in db: Connection) throws -> Tasting? {
        let query = Tables.tastings.filter(Tables.Tastings.id == id)
        guard let row = try db.pluck(query) else { return nil }
        return try from(row: row)
    }

    /// Get all tastings for a user
    static func forUser(_ userId: Int64, in db: Connection) throws -> [Tasting] {
        let query = Tables.tastings
            .filter(Tables.Tastings.userId == userId)
            .order(Tables.Tastings.createdAt.desc)

        return try db.prepare(query).map { try from(row: $0) }
    }

    /// Get unsynced tastings
    static func unsynced(in db: Connection) throws -> [Tasting] {
        let query = Tables.tastings
            .filter(Tables.Tastings.syncedAt == nil)
            .order(Tables.Tastings.createdAt.asc)

        return try db.prepare(query).map { try from(row: $0) }
    }

    /// Mark as synced
    func markSynced(in db: Connection) throws {
        let tasting = Tables.tastings.filter(Tables.Tastings.id == id)
        try db.run(tasting.update(
            Tables.Tastings.syncedAt <- Date()
        ))
    }
}
