import Fluent

final class UserCredential: Model, @unchecked Sendable {
    static let schema = "user_credentials"
    static let space = "auth"

    // MARK: - Fields

    @ID(key: .id)
    var id: UUID?

    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "password_salt")
    var passwordSalt: String

    @Field(key: "failed_attempts")
    var failedAttempts: Int

    @OptionalField(key: "locked_until")
    var lockedUntil: Date?

    @OptionalField(key: "last_changed_at")
    var lastChangedAt: Date?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    // MARK: - Relations

    @Parent(key: "user_id")
    var user: User

    // MARK: - Computed

    var isLocked: Bool {
        guard let lockedUntil else { return false }
        return lockedUntil > Date()
    }

    // MARK: - Init

    init() {}

    init(
        id: UUID? = nil,
        userID: User.IDValue,
        passwordHash: String,
        passwordSalt: String
    ) {
        self.id = id
        self.$user.id = userID
        self.passwordHash = passwordHash
        self.passwordSalt = passwordSalt
        self.failedAttempts = 0
    }
}