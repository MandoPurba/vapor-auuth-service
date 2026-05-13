import Fluent

struct CreateSessions: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("sessions", space: "auth")
            .id()
            .field("user_id", .uuid, .required)
            .foreignKey("user_id", references: "users", inSpace: "auth", "id", onDelete: .cascade)
            .field("device_id", .uuid, .required)
            .foreignKey("device_id", references: "user_devices", inSpace: "auth", "id", onDelete: .cascade)
            .field("session_token", .string, .required)
            .unique(on: "session_token")
            .field("ip_address", .string)
            .field("user_agent", .sql(.text))
            .field("auth_method", .string, .required)    // password | biometric | oauth | mfa
            .field("is_active", .bool, .required, .sql(.default(true)))
            .field("expires_at", .datetime, .required)
            .field("last_activity_at", .datetime)
            .field("created_at", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("sessions", space: "auth").delete()
    }
}