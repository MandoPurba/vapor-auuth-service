import Fluent
import SQLKit

struct CreateAuthSchema: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let sql = database as! any SQLDatabase
        try await sql.raw("CREATE SCHEMA IF NOT EXISTS auth").run()
    }

    func revert(on database: any Database) async throws {
        let sql = database as! any SQLDatabase
        try await sql.raw("DROP SCHEMA IF EXISTS auth CASCADE").run()
    }
}