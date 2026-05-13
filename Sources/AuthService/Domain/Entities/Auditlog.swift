import Fluent

final class AuditLog: Model, @unchecked Sendable {
    static let schema = "audit_logs"
    static let space = "auth"

    // MARK: - Enums

    enum Action: String, Codable {
        // Auth
        case loginSuccess      = "login.success"
        case loginFailed       = "login.failed"
        case loginLockedOut    = "login.locked_out"
        case logoutSuccess     = "logout.success"
        // Biometric
        case biometricRegistered  = "biometric.registered"
        case biometricVerified    = "biometric.verified"
        case biometricRevoked     = "biometric.revoked"
        // Password
        case passwordChanged      = "password.changed"
        case passwordResetRequest = "password.reset_request"
        case passwordResetSuccess = "password.reset_success"
        // Session
        case sessionRevoked       = "session.revoked"
        case sessionExpired       = "session.expired"
        case tokenRefreshed       = "token.refreshed"
        case tokenReuseDetected   = "token.reuse_detected"
        // Device
        case deviceRegistered     = "device.registered"
        case deviceTrusted        = "device.trusted"
        case deviceRevoked        = "device.revoked"
        // MFA
        case mfaEnabled           = "mfa.enabled"
        case mfaDisabled          = "mfa.disabled"
        case mfaVerified          = "mfa.verified"
        case mfaFailed            = "mfa.failed"
    }

    enum Result: String, Codable {
        case success
        case failure
        case error
    }

    // MARK: - Fields

    @ID(key: .id)
    var id: UUID?

    @Field(key: "action")
    var action: String

    @OptionalField(key: "ip_address")
    var ipAddress: String?

    @OptionalField(key: "user_agent")
    var userAgent: String?

    /// Data konteks tambahan spesifik per action — e.g. {"reason": "wrong_password", "attempt": 3}
    @OptionalField(key: "metadata")
    var metadata: [String: String]?

    @Field(key: "result")
    var result: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // MARK: - Relations
    // Semua FK nullable — log tidak boleh dihapus meski entitas terkait dihapus

    @OptionalParent(key: "user_id")
    var user: User?

    @OptionalParent(key: "session_id")
    var session: Session?

    @OptionalParent(key: "device_id")
    var device: UserDevice?

    // MARK: - Init

    init() {}

    init(
        id: UUID? = nil,
        userID: User.IDValue? = nil,
        sessionID: Session.IDValue? = nil,
        deviceID: UserDevice.IDValue? = nil,
        action: Action,
        result: Result,
        ipAddress: String? = nil,
        userAgent: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.$session.id = sessionID
        self.$device.id = deviceID
        self.action = action.rawValue
        self.result = result.rawValue
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.metadata = metadata
    }
}