import Fluent

struct CreateRefreshTokens: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("refresh_tokens", space: "auth")
            .id()
            .field("user_id", .uuid, .required)
            .foreignKey("user_id", references: "users", "id", space: "auth", onDelete: .cascade)
            .field("session_id", .uuid, .required)
            .foreignKey("session_id", references: "sessions", "id", space: "auth", onDelete: .cascade)
            .field("token_hash", .string, .required)     // SHA-256 hash of the raw token
            .unique(on: "token_hash")
            .field("family_id", .string, .required)      // UUID string, grup token untuk deteksi reuse
            .field("is_revoked", .bool, .required, .sql(.default(false)))
            .field("expires_at", .datetime, .required)
            .field("rotated_at", .datetime)
            .field("created_at", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("refresh_tokens", space: "auth").delete()
    }
}