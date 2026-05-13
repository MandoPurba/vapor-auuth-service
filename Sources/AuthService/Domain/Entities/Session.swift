import Fluent

final class Session: Model, @unchecked Sendable {
    static let schema = "sessions"
    static let space = "auth"

    // MARK: - Enums

    enum AuthMethod: String, Codable {
        case password
        case biometric
        case oauth
        case mfa
    }

    // MARK: - Fields

    @ID(key: .id)
    var id: UUID?

    @Field(key: "session_token")
    var sessionToken: String

    @OptionalField(key: "ip_address")
    var ipAddress: String?

    @OptionalField(key: "user_agent")
    var userAgent: String?

    @Field(key: "auth_method")
    var authMethod: String

    @Field(key: "is_active")
    var isActive: Bool

    @Field(key: "expires_at")
    var expiresAt: Date

    @OptionalField(key: "last_activity_at")
    var lastActivityAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // MARK: - Relations

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "device_id")
    var device: UserDevice

    @Children(for: \.$session)
    var refreshTokens: [RefreshToken]

    @Children(for: \.$session)
    var auditLogs: [AuditLog]

    // MARK: - Computed

    var isExpired: Bool { expiresAt < Date() }
    var isValid: Bool { isActive && !isExpired }

    // MARK: - Init

    init() {}

    init(
        id: UUID? = nil,
        userID: User.IDValue,
        deviceID: UserDevice.IDValue,
        sessionToken: String,
        authMethod: AuthMethod,
        ipAddress: String? = nil,
        userAgent: String? = nil,
        expiresAt: Date
    ) {
        self.id = id
        self.$user.id = userID
        self.$device.id = deviceID
        self.sessionToken = sessionToken
        self.authMethod = authMethod.rawValue
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.isActive = true
        self.expiresAt = expiresAt
    }
}