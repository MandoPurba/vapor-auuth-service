import Fluent

final class MfaMethod: Model, @unchecked Sendable {
    static let schema = "mfa_methods"
    static let space = "auth"

    // MARK: - Enums

    enum MethodType: String, Codable {
        case totp
        case sms
        case emailOTP = "email_otp"
        case biometric
    }

    // MARK: - Fields

    @ID(key: .id)
    var id: UUID?

    @Field(key: "method_type")
    var methodType: String

    /// TOTP secret — dienkripsi at-rest sebelum disimpan, decrypt saat verifikasi
    @OptionalField(key: "secret_encrypted")
    var secretEncrypted: String?

    /// Diisi hanya untuk method_type = sms
    @OptionalField(key: "phone_number")
    var phoneNumber: String?

    @Field(key: "is_primary")
    var isPrimary: Bool

    @Field(key: "is_verified")
    var isVerified: Bool

    @OptionalField(key: "verified_at")
    var verifiedAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    // MARK: - Relations

    @Parent(key: "user_id")
    var user: User

    // MARK: - Init

    init() {}

    init(
        id: UUID? = nil,
        userID: User.IDValue,
        methodType: MethodType,
        secretEncrypted: String? = nil,
        phoneNumber: String? = nil,
        isPrimary: Bool = false
    ) {
        self.id = id
        self.$user.id = userID
        self.methodType = methodType.rawValue
        self.secretEncrypted = secretEncrypted
        self.phoneNumber = phoneNumber
        self.isPrimary = isPrimary
        self.isVerified = false
    }
}