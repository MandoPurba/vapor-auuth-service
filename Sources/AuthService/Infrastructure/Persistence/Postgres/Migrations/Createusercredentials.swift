import Fluent

struct CreateUserCredentials: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("user_credentials", space: "auth")
            .id()
            .field("user_id", .uuid, .required)
            .foreignKey("user_id", references: "users", inSpace: "auth", "id", onDelete: .cascade)
            .field("password_hash", .string, .required)
            .field("password_salt", .string, .required)
            .field("failed_attempts", .int16, .required, .sql(.default(0)))
            .field("locked_until", .datetime)
            .field("last_changed_at", .datetime)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("user_credentials", space: "auth").delete()
    }
}