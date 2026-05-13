import Fluent

final class BiometricCredential: Model, @unchecked Sendable {
    static let schema = "biometric_credentials"
    static let space = "auth"

    // MARK: - Enums

    enum AttestationType: String, Codable {
        case none
        case `self`
        case packed
        case tpm
        case androidKey = "android-key"
        case fidoU2F = "fido-u2f"
    }

    enum Transport: String, Codable {
        case `internal`
        case usb
        case nfc
        case ble
        case hybrid
    }

    // MARK: - Fields

    @ID(key: .id)
    var id: UUID?

    /// WebAuthn credential ID — base64url encoded, diterima dari authenticator
    @Field(key: "credential_id")
    var credentialId: String

    /// COSE-encoded public key — base64url encoded
    @Field(key: "public_key")
    var publicKey: String

    /// Authenticator Attestation GUID — mengidentifikasi model/vendor authenticator
    @OptionalField(key: "aaguid")
    var aaguid: String?

    /// Counter kriptografis — deteksi cloning jika nilai dari DB > nilai dari authenticator
    @Field(key: "sign_count")
    var signCount: Int

    @OptionalField(key: "attestation_type")
    var attestationType: String?

    /// Transport yang didukung authenticator ini, disimpan sebagai JSON array
    @OptionalField(key: "transports")
    var transports: [String]?

    @Field(key: "is_active")
    var isActive: Bool

    @OptionalField(key: "last_used_at")
    var lastUsedAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    // MARK: - Relations

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "device_id")
    var device: UserDevice

    // MARK: - Init

    init() {}

    init(
        id: UUID? = nil,
        userID: User.IDValue,
        deviceID: UserDevice.IDValue,
        credentialId: String,
        publicKey: String,
        aaguid: String? = nil,
        signCount: Int = 0,
        attestationType: AttestationType? = nil,
        transports: [Transport]? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.$device.id = deviceID
        self.credentialId = credentialId
        self.publicKey = publicKey
        self.aaguid = aaguid
        self.signCount = signCount
        self.attestationType = attestationType?.rawValue
        self.transports = transports?.map(\.rawValue)
        self.isActive = true
    }
}