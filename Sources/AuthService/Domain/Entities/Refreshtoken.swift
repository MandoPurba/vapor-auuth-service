import Fluent

final class RefreshToken: Model, @unchecked Sendable {
    static let schema = "refresh_tokens"
    static let space = "auth"

    // MARK: - Fields

    @ID(key: .id)
    var id: UUID?

    /// SHA-256 hash dari raw token — raw token tidak pernah disimpan di DB
    @Field(key: "token_hash")
    var tokenHash: String

    /// Group ID untuk token rotation — seluruh family di-revoke jika ada reuse
    @Field(key: "family_id")
    var familyId: String

    @Field(key: "is_revoked")
    var isRevoked: Bool

    @Field(key: "expires_at")
    var expiresAt: Date

    @OptionalField(key: "rotated_at")
    var rotatedAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    // MARK: - Relations

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "session_id")
    var session: Session

    // MARK: - Computed

    var isExpired: Bool { expiresAt < Date() }
    var isValid: Bool { !isRevoked && !isExpired }

    // MARK: - Init

    init() {}

    init(
        id: UUID? = nil,
        userID: User.IDValue,
        sessionID: Session.IDValue,
        tokenHash: String,
        familyId: String,
        expiresAt: Date
    ) {
        self.id = id
        self.$user.id = userID
        self.$session.id = sessionID
        self.tokenHash = tokenHash
        self.familyId = familyId
        self.isRevoked = false
        self.expiresAt = expiresAt
    }
}