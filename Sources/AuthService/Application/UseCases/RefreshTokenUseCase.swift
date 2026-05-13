import Fluent
import Crypto

// ============================================================
// MARK: - RefreshTokenUseCase
// ============================================================
// Alur (Token Rotation):
//  1. Hash raw token yang diterima
//  2. Cari di DB berdasarkan hash
//  3. Cek revoked — jika iya: REUSE DETECTED → revoke seluruh family
//  4. Cek expired
//  5. Load session — validasi masih aktif
//  6. Revoke token lama
//  7. Generate token pair baru
//  8. Simpan RefreshToken baru (family ID sama — untuk melacak silsilah)
//  9. Update session.last_activity_at
// 10. Tulis AuditLog
// 11. Return AuthResponseDTO baru

final class RefreshTokenUseCase: Sendable {

    private let refreshTokenRepo: any RefreshTokenRepository
    private let sessionRepo: any SessionRepository
    private let userRepo: any UserRepository
    private let deviceRepo: any UserDeviceRepository
    private let auditLogRepo: any AuditLogRepository
    private let tokenService: any TokenService

    init(
        refreshTokenRepo: any RefreshTokenRepository,
        sessionRepo: any SessionRepository,
        userRepo: any UserRepository,
        deviceRepo: any UserDeviceRepository,
        auditLogRepo: any AuditLogRepository,
        tokenService: any TokenService
    ) {
        self.refreshTokenRepo = refreshTokenRepo
        self.sessionRepo = sessionRepo
        self.userRepo = userRepo
        self.deviceRepo = deviceRepo
        self.auditLogRepo = auditLogRepo
        self.tokenService = tokenService
    }

    func execute(_ req: RefreshTokenRequestDTO, on db: any Database) async throws -> AuthResponseDTO {

        // 1. Hash raw token
        let tokenHash = SHA256.hash(data: Data(req.refreshToken.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()

        // 2. Cari token di DB
        guard let storedToken = try await refreshTokenRepo.findByTokenHash(tokenHash, on: db) else {
            throw AuthError.refreshTokenNotFound
        }

        // 3. Deteksi reuse — token ditemukan tapi sudah di-revoke
        //    Ini berarti token yang sama dipakai dua kali → kemungkinan token theft
        if storedToken.isRevoked {
            // Revoke seluruh family — paksa logout semua session dari silsilah token ini
            try await refreshTokenRepo.revokeFamily(storedToken.familyId, on: db)

            // Cari session yang terkait untuk di-revoke juga
            if let session = try? await sessionRepo.findByID(storedToken.$session.id, on: db) {
                session.isActive = false
                try? await sessionRepo.update(session, on: db)
            }

            let log = AuditLog(
                userID: storedToken.$user.id,
                sessionID: storedToken.$session.id,
                action: .tokenReuseDetected,
                result: .failure,
                metadata: ["family_id": storedToken.familyId]
            )
            try? await auditLogRepo.create(log, on: db)

            throw AuthError.refreshTokenFamilyCompromised
        }

        // 4. Cek expired
        guard !storedToken.isExpired else {
            throw AuthError.refreshTokenExpired
        }

        // 5. Load + validasi session
        guard let session = try await sessionRepo.findByID(storedToken.$session.id, on: db) else {
            throw AuthError.sessionNotFound
        }
        guard session.isActive else {
            throw AuthError.sessionInactive
        }
        guard !session.isExpired else {
            throw AuthError.sessionExpired
        }

        // 6. Revoke token lama (soft — tandai is_revoked, bukan hapus)
        storedToken.isRevoked = true
        storedToken.rotatedAt = Date()
        try await refreshTokenRepo.update(storedToken, on: db)

        // 7. Generate token pair baru
        let userID = storedToken.$user.id
        let tokens = try tokenService.generateTokenPair(
            userID: userID,
            sessionID: session.requireID()
        )

        // 8. Simpan RefreshToken baru — family ID SAMA untuk melacak silsilah
        let newRefreshToken = RefreshToken(
            userID: userID,
            sessionID: session.requireID(),
            tokenHash: tokens.refreshTokenHash,
            familyId: storedToken.familyId,     // ← pertahankan family ID
            expiresAt: tokens.refreshTokenExpiresAt
        )
        try await refreshTokenRepo.create(newRefreshToken, on: db)

        // 9. Update session activity
        session.lastActivityAt = Date()
        try await sessionRepo.update(session, on: db)

        // 10. Audit log
        let log = AuditLog(
            userID: userID,
            sessionID: session.id,
            action: .tokenRefreshed,
            result: .success
        )
        try await auditLogRepo.create(log, on: db)

        // 11. Load user untuk response
        guard let user = try await userRepo.findByID(userID, on: db) else {
            throw AuthError.userNotFound
        }

        return AuthResponseDTO(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            tokenType: "Bearer",
            expiresIn: tokens.accessTokenExpiresIn,
            user: UserResponseDTO(from: user),
            session: SessionResponseDTO(from: session)
        )
    }
}