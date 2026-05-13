import Fluent
import Vapor

// ============================================================
// MARK: - RegisterUseCase
// ============================================================
// Alur:
//  1. Validasi input (password strength, email format)
//  2. Cek email belum terdaftar
//  3. Hash password
//  4. Simpan User + UserCredential dalam satu transaksi
//  5. Upsert device (jika fingerprint sudah ada, update; jika baru, create)
//  6. Buat Session + TokenPair
//  7. Simpan RefreshToken (hash-nya)
//  8. Tulis AuditLog
//  9. Return AuthResponseDTO

final class RegisterUseCase: Sendable {

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

    func execute(_ req: RegisterRequestDTO, on db: any Database) async throws -> AuthResponseDTO {

        // 1. Validasi password
        try passwordService.validate(req.password)

        // 2. Cek email belum terdaftar
        if try await userRepo.findByEmail(req.email.lowercased(), on: db) != nil {
            throw AuthError.emailAlreadyExists
        }

        // 3. Hash password
        let (hash, salt) = try passwordService.hash(req.password)

        // 4. Simpan User + UserCredential dalam satu transaksi
        let user = User(
            email: req.email.lowercased(),
            displayName: req.displayName
        )

        try await db.transaction { tx in
            try await userRepo.create(user, on: tx)

            let credential = UserCredential(
                userID: user.requireID(),
                passwordHash: hash,
                passwordSalt: salt
            )
            try await credentialRepo.create(credential, on: tx)
        }

        // 5. Upsert device
        let device = try await upsertDevice(req, userID: user.requireID(), on: db)

        // 6. Buat Session
        let sessionDuration: TimeInterval = 60 * 60 * 24 * 7   // 7 hari
        let session = Session(
            userID: user.requireID(),
            deviceID: device.requireID(),
            sessionToken: UUID().uuidString,
            authMethod: .password,
            expiresAt: Date().addingTimeInterval(sessionDuration)
        )
        try await sessionRepo.create(session, on: db)

        // 7. Generate + simpan token pair
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

        // 8. Audit log
        let log = AuditLog(
            userID: user.id,
            sessionID: session.id,
            deviceID: device.id,
            action: .loginSuccess,
            result: .success,
            metadata: ["method": "register"]
        )
        try await auditLogRepo.create(log, on: db)

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

    private func upsertDevice(
        _ req: RegisterRequestDTO,
        userID: UUID,
        on db: any Database
    ) async throws -> UserDevice {
        if let existing = try await deviceRepo.findByFingerprint(req.deviceFingerprint, on: db) {
            existing.lastSeenAt = Date()
            existing.appVersion = req.appVersion
            existing.pushToken = nil    // reset — akan diisi ulang saat login
            try await deviceRepo.update(existing, on: db)
            return existing
        }

        let deviceType = UserDevice.DeviceType(rawValue: req.deviceType) ?? .phone
        let platform = UserDevice.Platform(rawValue: req.platform) ?? .ios

        let device = UserDevice(
            userID: userID,
            deviceName: req.deviceName,
            deviceType: deviceType,
            platform: platform,
            osVersion: req.osVersion,
            appVersion: req.appVersion,
            deviceFingerprint: req.deviceFingerprint
        )
        try await deviceRepo.create(device, on: db)
        return device
    }
}