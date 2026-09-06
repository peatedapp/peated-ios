@testable import PeatedCore
import SQLite
import Testing

struct DatabaseManagerTests {
    @Test
    func inMemoryDatabaseRunsAllMigrations() throws {
        let manager = try DatabaseManager(databasePath: ":memory:")
        let versionTable = Table("schema_version")
        let version = Expression<Int>("version")

        let schemaVersion = try manager.connection.scalar(versionTable.select(version.max))
        let foreignKeysEnabled = try manager.connection.scalar("PRAGMA foreign_keys") as? Int64

        #expect(schemaVersion == 4)
        #expect(foreignKeysEnabled == 1)

        let ratingBandColumnCount = try manager.connection.scalar(
            "SELECT count(*) FROM pragma_table_info('tastings') WHERE name = 'rating_band'"
        ) as? Int64
        #expect(ratingBandColumnCount == 1)
    }
}
