import Fluent

struct CreateAuditLogs: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("audit_logs", space: "auth")
            .id()
            // nullable FKs — log tetap tersimpan meski user/session/device sudah dihapus
            .field("user_id", .uuid)
            .foreignKey("user_id", references: "users", inSpace: "auth", "id", onDelete: .setNull)
            .field("session_id", .uuid)
            .foreignKey("session_id", references: "sessions", inSpace: "auth", "id", onDelete: .setNull)
            .field("device_id", .uuid)
            .foreignKey("device_id", references: "user_devices", inSpace: "auth", "id", onDelete: .setNull)
            .field("action", .string, .required)         // login.success | login.failed | biometric.registered | password.changed | session.revoked | device.trusted
            .field("ip_address", .string)
            .field("user_agent", .sql(.text))
            .field("metadata", .json)                    // data tambahan spesifik per action
            .field("result", .string, .required)         // success | failure | error
            .field("created_at", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("audit_logs", space: "auth").delete()
    }
}