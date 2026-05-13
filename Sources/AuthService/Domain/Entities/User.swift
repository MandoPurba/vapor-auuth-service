import Fluent
import Vapor

final class User: Model, @unchecked Sendable {
    static let schema = "users"
    static let space = "auth"

    // MARK: - Fields

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @OptionalField(key: "phone_number")
    var phoneNumber: String?

    @OptionalField(key: "display_name")
    var displayName: String?

    @OptionalField(key: "avatar_url")
    var avatarURL: String?

    @Field(key: "is_active")
    var isActive: Bool

    @Field(key: "is_email_verified")
    var isEmailVerified: Bool

    @Field(key: "is_phone_verified")
    var isPhoneVerified: Bool

    @OptionalField(key: "email_verified_at")
    var emailVerifiedAt: Date?

    @OptionalField(key: "last_login_at")
    var lastLoginAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @OptionalField(key: "deleted_at")
    var deletedAt: Date?

    // MARK: - Relations

    @OptionalChild(for: \.$user)
    var credential: UserCredential?

    @Children(for: \.$user)
    var devices: [UserDevice]

    @Children(for: \.$user)
    var sessions: [Session]

    @Children(for: \.$user)
    var refreshTokens: [RefreshToken]

    @Children(for: \.$user)
    var biometricCredentials: [BiometricCredential]

    @Children(for: \.$user)
    var mfaMethods: [MfaMethod]

    @Children(for: \.$user)
    var auditLogs: [AuditLog]

    // MARK: - Init

    init() {}

    init(
        id: UUID? = nil,
        email: String,
        phoneNumber: String? = nil,
        displayName: String? = nil,
        avatarURL: String? = nil,
        isActive: Bool = true,
        isEmailVerified: Bool = false,
        isPhoneVerified: Bool = false
    ) {
        self.id = id
        self.email = email
        self.phoneNumber = phoneNumber
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.isActive = isActive
        self.isEmailVerified = isEmailVerified
        self.isPhoneVerified = isPhoneVerified
    }
}