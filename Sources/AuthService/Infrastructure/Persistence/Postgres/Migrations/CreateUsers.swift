import Fluent

struct CreateUsers: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users", space: "auth")
            .id()
            .field("email", .string, .required)
            .unique(on: "email")
            .field("phone_number", .string)
            .field("display_name", .string)
            .field("avatar_url", .string)
            .field("is_active", .bool, .required, .sql(.default(true)))
            .field("is_email_verified", .bool, .required, .sql(.default(false)))
            .field("is_phone_verified", .bool, .required, .sql(.default(false)))
            .field("email_verified_at", .datetime)
            .field("last_login_at", .datetime)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .field("deleted_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users", space: "auth").delete()
    }
}