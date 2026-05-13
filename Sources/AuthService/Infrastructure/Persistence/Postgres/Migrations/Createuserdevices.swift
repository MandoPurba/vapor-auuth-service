import Fluent

struct CreateUserDevices: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("user_devices", space: "auth")
            .id()
            .field("user_id", .uuid, .required)
            .foreignKey("user_id", references: "users", inSpace: "auth", "id", onDelete: .cascade)
            .field("device_name", .string, .required)
            .field("device_type", .string, .required)   // phone, tablet, desktop, watch
            .field("platform", .string, .required)       // ios, android, web
            .field("os_version", .string)
            .field("app_version", .string)
            .field("push_token", .string)
            .field("device_fingerprint", .string, .required)
            .unique(on: "device_fingerprint")
            .field("is_trusted", .bool, .required, .sql(.default(false)))
            .field("is_active", .bool, .required, .sql(.default(true)))
            .field("trusted_at", .datetime)
            .field("last_seen_at", .datetime)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("user_devices", space: "auth").delete()
    }
}