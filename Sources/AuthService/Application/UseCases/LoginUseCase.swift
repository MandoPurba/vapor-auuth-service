import Fluent
import Vapor

// ============================================================
// MARK: - LoginUseCase
// ============================================================
// Alur:
//  1. Cari user by email
//  2. Cek akun aktif
//  3. Cek lockout
//  4. Verifikasi password
//  5. Reset failed_attempts jika sukses / increment jika gagal
//  6. Upsert device
//  7. Buat Session + TokenPair
//  8. Simpan RefreshToken
//  9. Update last_login_at
// 10. Tulis AuditLog
// 11. Return AuthResponseDTO

final class LoginUseCase: Sendable {

    private let maxFailedAttempts = 5
    private let lockoutDuration: TimeInterval = 60 * 15     // 15 menit
    private let sessionDuration: TimeInterval = 60 * 60 * 24 * 7   // 7 hari

    private let userRepo: any UserRepository
    private let credentialRepo: any UserCredentialRepository
    private let deviceRepo: any UserDeviceRepository
    private let sessionRepo: any SessionRepository
    private let refreshTokenRepo: any RefreshTokenRepository
    private let auditLogRepo: any AuditLogRepository
    private let passwordService: any PasswordService
    private let tokenService: any TokenService

    init(
        userRepo: any UserRepository,
        credentialRepo: any UserCredentialRepository,
        deviceRepo: any UserDeviceRepository,
        sessionRepo: any SessionRepository,
        refreshTokenRepo: any RefreshTokenRepository,
        auditLogRepo: any AuditLogRepository,
        passwordService: any PasswordService,
        tokenService: any TokenService
    ) {
        self.userRepo = userRepo
        self.credentialRepo = credentialRepo
        self.deviceRepo = deviceRepo
        self.sessionRepo = sessionRepo
        self.refreshTokenRepo = refreshTokenRepo
        self.auditLogRepo = auditLogRepo
        self.passwordService = passwordService
        self.tokenService = tokenService
    }

    func execute(_ req: LoginRequestDTO, on db: any Database) async throws -> AuthResponseDTO {

        // 1. Cari user
        guard let user = try await userRepo.findByEmail(req.email.lowercased(), on: db) else {
            // Jangan beri tahu apakah email terdaftar atau tidak
            throw AuthError.invalidCredentials
        }

        // 2. Cek akun aktif
        guard user.isActive else {
            throw AuthError.accountInactive
        }

        // 3. Cek lockout
        guard let credential = try await credentialRepo.findByUserID(user.requireID(), on: db) else {
            throw AuthError.invalidCredentials
        }

        if credential.isLocked {
            await writeAuditLog(
                userID: user.id, action: .loginLockedOut, result: .failure,
                ipAddress: req.ipAddress, userAgent: req.userAgent, on: db
            )
            throw AuthError.accountLocked(until: credential.lockedUntil!)
        }

        // 4. Verifikasi password
        let isValid = try passwordService.verify(
            req.password,
            hash: credential.passwordHash,
            salt: credential.passwordSalt
        )

        guard isValid else {
            try await handleFailedAttempt(credential: credential, on: db)
            await writeAuditLog(
                userID: user.id, action: .loginFailed, result: .failure,
                ipAddress: req.ipAddress, userAgent: req.userAgent, on: db
            )
            throw AuthError.invalidCredentials
        }

        // 5. Reset failed attempts setelah login sukses
        if credential.failedAttempts > 0 {
            credential.failedAttempts = 0
            credential.lockedUntil = nil
            try await credentialRepo.update(credential, on: db)
        }

        // 6. Upsert device
        let device = try await upsertDevice(req, userID: user.requireID(), on: db)

        // 7. Buat Session
        let session = Session(
            userID: user.requireID(),
            deviceID: device.requireID(),
            sessionToken: UUID().uuidString,
            authMethod: .password,
            ipAddress: req.ipAddress,
            userAgent: req.userAgent,
            expiresAt: Date().addingTimeInterval(sessionDuration)
        )
        try await sessionRepo.create(session, on: db)

        // 8. Generate + simpan token pair
        let tokens = try tokenService.generateTokenPair(
            userID: user.requireID(),
            sessionID: session.requireID()
        )
        let refreshToken = RefreshToken(
            userID: user.requireID(),
            sessionID: session.requireID(),
            tokenHash: tokens.refreshTokenHash,
            familyId: UUID().uuidString,
            expiresAt: tokens.refreshTokenExpiresAt
        )
        try await refreshTokenRepo.create(refreshToken, on: db)

        // 9. Update last login
        user.lastLoginAt = Date()
        device.lastSeenAt = Date()
        try await userRepo.update(user, on: db)
        try await deviceRepo.update(device, on: db)

        // 10. Audit log
        await writeAuditLog(
            userID: user.id, sessionID: session.id, deviceID: device.id,
            action: .loginSuccess, result: .success,
            ipAddress: req.ipAddress, userAgent: req.userAgent, on: db
        )

        return AuthResponseDTO(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            tokenType: "Bearer",
            expiresIn: tokens.accessTokenExpiresIn,
            user: UserResponseDTO(from: user),
            session: SessionResponseDTO(from: session)
        )
    }

    // MARK: - Private

    private func handleFailedAttempt(credential: UserCredential, on db: any Database) async throws {
        credential.failedAttempts += 1
        if credential.failedAttempts >= maxFailedAttempts {
            credential.lockedUntil = Date().addingTimeInterval(lockoutDuration)
        }
        try await credentialRepo.update(credential, on: db)
    }

    private func upsertDevice(
        _ req: LoginRequestDTO,
        userID: UUID,
        on db: any Database
    ) async throws -> UserDevice {
        if let existing = try await deviceRepo.findByFingerprint(req.deviceFingerprint, on: db) {
            existing.lastSeenAt = Date()
            try await deviceRepo.update(existing, on: db)
            return existing
        }
        // Device baru — platform/type tidak diketahui dari login request, default phone/ios
        let device = UserDevice(
            userID: userID,
            deviceName: "Unknown Device",
            deviceType: .phone,
            platform: .ios,
            deviceFingerprint: req.deviceFingerprint
        )
        try await deviceRepo.create(device, on: db)
        return device
    }

    @discardableResult
    private func writeAuditLog(
        userID: UUID? = nil,
        sessionID: UUID? = nil,
        deviceID: UUID? = nil,
        action: AuditLog.Action,
        result: AuditLog.Result,
        ipAddress: String? = nil,
        userAgent: String? = nil,
        on db: any Database
    ) async -> Void {
        let log = AuditLog(
            userID: userID,
            sessionID: sessionID,
            deviceID: deviceID,
            action: action,
            result: result,
            ipAddress: ipAddress,
            userAgent: userAgent
        )
        try? await auditLogRepo.create(log, on: db)
    }
}