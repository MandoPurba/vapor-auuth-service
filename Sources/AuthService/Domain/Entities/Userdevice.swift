import Fluent

final class UserDevice: Model, @unchecked Sendable {
    static let schema = "user_devices"
    static let space = "auth"

    // MARK: - Enums

    enum Platform: String, Codable {
        case ios
        case android
        case web
    }

    enum DeviceType: String, Codable {
        case phone
        case tablet
        case desktop
        case watch
    }

    // MARK: - Fields

    @ID(key: .id)
    var id: UUID?

    @Field(key: "device_name")
    var deviceName: String

    @Field(key: "device_type")
    var deviceType: String

    @Field(key: "platform")
    var platform: String

    @OptionalField(key: "os_version")
    var osVersion: String?

    @OptionalField(key: "app_version")
    var appVersion: String?

    @OptionalField(key: "push_token")
    var pushToken: String?

    @Field(key: "device_fingerprint")
    var deviceFingerprint: String

    @Field(key: "is_trusted")
    var isTrusted: Bool

    @Field(key: "is_active")
    var isActive: Bool

    @OptionalField(key: "trusted_at")
    var trustedAt: Date?

    @OptionalField(key: "last_seen_at")
    var lastSeenAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    // MARK: - Relations

    @Parent(key: "user_id")
    var user: User

    @Children(for: \.$device)
    var sessions: [Session]

    @Children(for: \.$device)
    var biometricCredentials: [BiometricCredential]

    @Children(for: \.$device)
    var auditLogs: [AuditLog]

    // MARK: - Init

    init() {}

    init(
        id: UUID? = nil,
        userID: User.IDValue,
        deviceName: String,
        deviceType: DeviceType,
        platform: Platform,
        osVersion: String? = nil,
        appVersion: String? = nil,
        pushToken: String? = nil,
        deviceFingerprint: String
    ) {
        self.id = id
        self.$user.id = userID
        self.deviceName = deviceName
        self.deviceType = deviceType.rawValue
        self.platform = platform.rawValue
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.pushToken = pushToken
        self.deviceFingerprint = deviceFingerprint
        self.isTrusted = false
        self.isActive = true
    }
}