import Fluent
import Vapor

// ============================================================
// MARK: - BiometricAuthUseCase
// ============================================================
// Empat operasi WebAuthn:
//
//  A. generateRegistrationChallenge  — server buat challenge, simpan di Redis
//  B. verifyRegistration             — client kirim attestation, server verifikasi + simpan credential
//  C. generateAuthChallenge          — server buat challenge untuk login
//  D. verifyAssertion                — client kirim assertion, server verifikasi + update sign_count

final class BiometricAuthUseCase: Sendable {

    private let sessionDuration: TimeInterval = 60 * 60 * 24 * 30  // 30 hari untuk biometric session
    private let rpID: String
    private let rpName: String

    private let userRepo: any UserRepository
    private let deviceRepo: any UserDeviceRepository
    private let biometricRepo: any BiometricCredentialRepository
    private let sessionRepo: any SessionRepository
    private let refreshTokenRepo: any RefreshTokenRepository
    private let auditLogRepo: any AuditLogRepository
    private let webAuthnService: any WebAuthnService
    private let challengeStore: any ChallengeStore
    private let tokenService: any TokenService

    init(
        rpID: String,
        rpName: String,
        userRepo: any UserRepository,
        deviceRepo: any UserDeviceRepository,
        biometricRepo: any BiometricCredentialRepository,
        sessionRepo: any SessionRepository,
        refreshTokenRepo: any RefreshTokenRepository,
        auditLogRepo: any AuditLogRepository,
        webAuthnService: any WebAuthnService,
        challengeStore: any ChallengeStore,
        tokenService: any TokenService
    ) {
        self.rpID = rpID
        self.rpName = rpName
        self.userRepo = userRepo
        self.deviceRepo = deviceRepo
        self.biometricRepo = biometricRepo
        self.sessionRepo = sessionRepo
        self.refreshTokenRepo = refreshTokenRepo
        self.auditLogRepo = auditLogRepo
        self.webAuthnService = webAuthnService
        self.challengeStore = challengeStore
        self.tokenService = tokenService
    }

    // =========================================================
    // MARK: A — Registration Challenge
    // =========================================================

    func generateRegistrationChallenge(
        req: BiometricRegisterChallengeRequestDTO,
        on db: any Database
    ) async throws -> BiometricRegisterChallengeResponseDTO {

        guard let user = try await userRepo.findByID(req.userID, on: db) else {
            throw AuthError.userNotFound
        }

        let challenge = try webAuthnService.generateChallenge()

        // Simpan challenge di Redis dengan TTL 5 menit
        // Key: "webauthn:register:<userID>"
        let cacheKey = "webauthn:register:\(user.requireID())"
        try await challengeStore.store(challenge: challenge.challenge, for: cacheKey, ttl: 300)

        let userIDBase64 = Data(user.requireID().uuidString.utf8)
            .base64EncodedString()
            .base64URLEncoded()

        return BiometricRegisterChallengeResponseDTO(
            challenge: challenge.challenge,
            rpID: rpID,
            rpName: rpName,
            userID: userIDBase64,
            userName: user.email
        )
    }

    // =========================================================
    // MARK: B — Registration Verification
    // =========================================================

    func verifyRegistration(
        req: BiometricRegisterRequestDTO,
        on db: any Database
    ) async throws -> BiometricCredentialResponseDTO {

        guard let user = try await userRepo.findByID(req.userID, on: db) else {
            throw AuthError.userNotFound
        }
        guard let device = try await deviceRepo.findByID(req.deviceID, on: db) else {
            throw AuthError.deviceNotFound
        }
        guard device.$user.id == user.requireID() else {
            throw AuthError.deviceNotBelongToUser
        }

        // Ambil + consume challenge dari Redis
        let cacheKey = "webauthn:register:\(user.requireID())"
        guard let storedChallenge = try await challengeStore.consume(for: cacheKey) else {
            throw AuthError.webAuthnChallengeMismatch
        }

        // Verifikasi attestation
        let verification = try webAuthnService.verifyRegistration(
            challenge: storedChallenge,
            clientDataJSON: req.clientDataJSON,
            attestationObject: req.attestationObject,
            expectedRpID: rpID
        )

        // Simpan credential
        let credential = BiometricCredential(
            userID: user.requireID(),
            deviceID: device.requireID(),
            credentialId: verification.credentialID,
            publicKey: verification.publicKey,
            aaguid: verification.aaguid,
            signCount: verification.signCount,
            attestationType: BiometricCredential.AttestationType(rawValue: verification.attestationType ?? "none"),
            transports: req.transports.map { $0.compactMap { BiometricCredential.Transport(rawValue: $0) } }
        )
        try await biometricRepo.create(credential, on: db)

        // Audit log
        let log = AuditLog(
            userID: user.id,
            deviceID: device.id,
            action: .biometricRegistered,
            result: .success,
            metadata: ["aaguid": verification.aaguid ?? "unknown"]
        )
        try await auditLogRepo.create(log, on: db)

        return BiometricCredentialResponseDTO(from: credential)
    }

    // =========================================================
    // MARK: C — Authentication Challenge
    // =========================================================

    func generateAuthChallenge(
        req: BiometricAuthChallengeRequestDTO,
        on db: any Database
    ) async throws -> BiometricAuthChallengeResponseDTO {

        // Cari credential berdasarkan hint credentialID dari client
        guard let credential = try await biometricRepo.findByCredentialID(req.credentialID, on: db) else {
            throw AuthError.biometricCredentialNotFound
        }
        guard credential.isActive else {
            throw AuthError.biometricCredentialInactive
        }

        let challenge = try webAuthnService.generateChallenge()

        // Key: "webauthn:auth:<credentialID>"
        let cacheKey = "webauthn:auth:\(credential.credentialId)"
        try await challengeStore.store(challenge: challenge.challenge, for: cacheKey, ttl: 300)

        // Kumpulkan semua active credential milik user (untuk allowCredentials list)
        let userID = credential.$user.id
        let allCredentials = try await biometricRepo.findActiveByUserID(userID, on: db)

        return BiometricAuthChallengeResponseDTO(
            challenge: challenge.challenge,
            rpID: rpID,
            allowedCredentialIDs: allCredentials.map(\.credentialId)
        )
    }

    // =========================================================
    // MARK: D — Assertion Verification (actual login)
    // =========================================================

    func verifyAssertion(
        req: BiometricAuthRequestDTO,
        on db: any Database
    ) async throws -> AuthResponseDTO {

        // Cari credential
        guard let credential = try await biometricRepo.findByCredentialID(req.credentialID, on: db) else {
            throw AuthError.biometricCredentialNotFound
        }
        guard credential.isActive else {
            throw AuthError.biometricCredentialInactive
        }

        // Consume challenge
        let cacheKey = "webauthn:auth:\(credential.credentialId)"
        guard let storedChallenge = try await challengeStore.consume(for: cacheKey) else {
            throw AuthError.webAuthnChallengeMismatch
        }

        // Verifikasi assertion — throws AuthError.webAuthnVerificationFailed jika gagal
        let verification: WebAuthnAssertionVerification
        do {
            verification = try webAuthnService.verifyAssertion(
                challenge: storedChallenge,
                credentialID: req.credentialID,
                clientDataJSON: req.clientDataJSON,
                authenticatorData: req.authenticatorData,
                signature: req.signature,
                publicKey: credential.publicKey,
                storedSignCount: credential.signCount,
                expectedRpID: rpID
            )
        } catch {
            let log = AuditLog(
                userID: credential.$user.id,
                deviceID: credential.$device.id,
                action: .loginFailed,
                result: .failure,
                ipAddress: req.ipAddress,
                userAgent: req.userAgent,
                metadata: ["method": "biometric", "reason": "assertion_failed"]
            )
            try? await auditLogRepo.create(log, on: db)
            throw AuthError.webAuthnVerificationFailed
        }

        // Validasi sign_count — harus selalu naik (kecuali 0, yang berarti stateless authenticator)
        if credential.signCount > 0 && verification.newSignCount <= credential.signCount {
            // Kemungkinan credential di-clone — revoke dan lempar error
            try await biometricRepo.revoke(credential, on: db)
            let log = AuditLog(
                userID: credential.$user.id,
                deviceID: credential.$device.id,
                action: .biometricRevoked,
                result: .failure,
                metadata: [
                    "reason": "sign_count_invalid",
                    "stored": "\(credential.signCount)",
                    "received": "\(verification.newSignCount)"
                ]
            )
            try? await auditLogRepo.create(log, on: db)
            throw AuthError.biometricSignCountInvalid
        }

        // Update sign_count + last_used_at
        credential.signCount = verification.newSignCount
        credential.lastUsedAt = Date()
        try await biometricRepo.update(credential, on: db)

        // Load user + device
        let userID = credential.$user.id
        guard let user = try await userRepo.findByID(userID, on: db) else {
            throw AuthError.userNotFound
        }
        guard let device = try await deviceRepo.findByID(credential.$device.id, on: db) else {
            throw AuthError.deviceNotFound
        }

        // Buat Session
        let session = Session(
            userID: userID,
            deviceID: device.requireID(),
            sessionToken: UUID().uuidString,
            authMethod: .biometric,
            ipAddress: req.ipAddress,
            userAgent: req.userAgent,
            expiresAt: Date().addingTimeInterval(sessionDuration)
        )
        try await sessionRepo.create(session, on: db)

        // Generate + simpan token pair
        let tokens = try tokenService.generateTokenPair(
            userID: userID,
            sessionID: session.requireID()
        )
        let refreshToken = RefreshToken(
            userID: userID,
            sessionID: session.requireID(),
            tokenHash: tokens.refreshTokenHash,
            familyId: UUID().uuidString,
            expiresAt: tokens.refreshTokenExpiresAt
        )
        try await refreshTokenRepo.create(refreshToken, on: db)

        // Update last login
        user.lastLoginAt = Date()
        device.lastSeenAt = Date()
        try await userRepo.update(user, on: db)
        try await deviceRepo.update(device, on: db)

        // Audit log
        let log = AuditLog(
            userID: user.id,
            sessionID: session.id,
            deviceID: device.id,
            action: .biometricVerified,
            result: .success,
            ipAddress: req.ipAddress,
            userAgent: req.userAgent
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
}

// MARK: - String extension untuk base64url encoding

private extension String {
    func base64URLEncoded() -> String {
        self.replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}