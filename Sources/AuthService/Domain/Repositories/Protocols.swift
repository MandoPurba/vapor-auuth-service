import Fluent

// ============================================================
// MARK: - UserRepository
// ============================================================

protocol UserRepository: Sendable {
    func findByID(_ id: UUID, on db: any Database) async throws -> User?
    func findByEmail(_ email: String, on db: any Database) async throws -> User?
    func create(_ user: User, on db: any Database) async throws
    func update(_ user: User, on db: any Database) async throws
    func softDelete(_ user: User, on db: any Database) async throws
}

// ============================================================
// MARK: - UserCredentialRepository
// ============================================================

protocol UserCredentialRepository: Sendable {
    func findByUserID(_ userID: UUID, on db: any Database) async throws -> UserCredential?
    func create(_ credential: UserCredential, on db: any Database) async throws
    func update(_ credential: UserCredential, on db: any Database) async throws
}

// ============================================================
// MARK: - UserDeviceRepository
// ============================================================

protocol UserDeviceRepository: Sendable {
    func findByID(_ id: UUID, on db: any Database) async throws -> UserDevice?
    func findByFingerprint(_ fingerprint: String, on db: any Database) async throws -> UserDevice?
    func findAllByUserID(_ userID: UUID, on db: any Database) async throws -> [UserDevice]
    func create(_ device: UserDevice, on db: any Database) async throws
    func update(_ device: UserDevice, on db: any Database) async throws
}

// ============================================================
// MARK: - SessionRepository
// ============================================================

protocol SessionRepository: Sendable {
    func findByID(_ id: UUID, on db: any Database) async throws -> Session?
    func findByToken(_ token: String, on db: any Database) async throws -> Session?
    func findActiveByUserID(_ userID: UUID, on db: any Database) async throws -> [Session]
    func create(_ session: Session, on db: any Database) async throws
    func update(_ session: Session, on db: any Database) async throws
    func revokeAll(forUserID userID: UUID, on db: any Database) async throws
    func revokeAll(forDeviceID deviceID: UUID, on db: any Database) async throws
}

// ============================================================
// MARK: - RefreshTokenRepository
// ============================================================

protocol RefreshTokenRepository: Sendable {
    func findByTokenHash(_ hash: String, on db: any Database) async throws -> RefreshToken?
    func findValidByTokenHash(_ hash: String, on db: any Database) async throws -> RefreshToken?
    func create(_ token: RefreshToken, on db: any Database) async throws
    func update(_ token: RefreshToken, on db: any Database) async throws
    /// Revoke seluruh token dalam satu family — dipanggil saat token reuse terdeteksi
    func revokeFamily(_ familyID: String, on db: any Database) async throws
}

// ============================================================
// MARK: - BiometricCredentialRepository
// ============================================================

protocol BiometricCredentialRepository: Sendable {
    func findByCredentialID(_ credentialID: String, on db: any Database) async throws -> BiometricCredential?
    func findActiveByUserID(_ userID: UUID, on db: any Database) async throws -> [BiometricCredential]
    func findActiveByDeviceID(_ deviceID: UUID, on db: any Database) async throws -> [BiometricCredential]
    func create(_ credential: BiometricCredential, on db: any Database) async throws
    func update(_ credential: BiometricCredential, on db: any Database) async throws
    func revoke(_ credential: BiometricCredential, on db: any Database) async throws
}

// ============================================================
// MARK: - AuditLogRepository
// ============================================================

protocol AuditLogRepository: Sendable {
    func create(_ log: AuditLog, on db: any Database) async throws
    func findByUserID(_ userID: UUID, limit: Int, on db: any Database) async throws -> [AuditLog]
}