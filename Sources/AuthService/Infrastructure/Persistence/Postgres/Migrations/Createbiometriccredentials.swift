import Fluent

struct CreateBiometricCredentials: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("biometric_credentials", space: "auth")
            .id()
            .field("user_id", .uuid, .required)
            .foreignKey("user_id", references: "users", inSpace: "auth", "id", onDelete: .cascade)
            .field("device_id", .uuid, .required)
            .foreignKey("device_id", references: "user_devices", inSpace: "auth", "id", onDelete: .cascade)
            .field("credential_id", .string, .required)  // WebAuthn credential ID (base64url)
            .unique(on: "credential_id")
            .field("public_key", .sql(.text), .required) // COSE-encoded public key (base64url)
            .field("aaguid", .string)                    // authenticator model identifier
            .field("sign_count", .int64, .required, .sql(.default(0)))
            .field("attestation_type", .string)          // none | self | packed | tpm | android-key | fido-u2f
            .field("transports", .json)                  // ["internal"] | ["usb"] | ["nfc"] | ["ble"] | ["hybrid"]
            .field("is_active", .bool, .required, .sql(.default(true)))
            .field("last_used_at", .datetime)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("biometric_credentials", space: "auth").delete()
    }
}