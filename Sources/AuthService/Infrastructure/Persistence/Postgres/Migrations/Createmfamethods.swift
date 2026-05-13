import Fluent

struct CreateMfaMethods: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("mfa_methods", space: "auth")
            .id()
            .field("user_id", .uuid, .required)
            .foreignKey("user_id", references: "users", inSpace: "auth", "id", onDelete: .cascade)
            .field("method_type", .string, .required)    // totp | sms | email_otp | biometric
            .field("secret_encrypted", .sql(.text))      // TOTP secret, dienkripsi at-rest
            .field("phone_number", .string)              // untuk method_type = sms
            .field("is_primary", .bool, .required, .sql(.default(false)))
            .field("is_verified", .bool, .required, .sql(.default(false)))
            .field("verified_at", .datetime)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("mfa_methods", space: "auth").delete()
    }
}