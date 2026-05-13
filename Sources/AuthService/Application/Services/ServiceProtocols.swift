import Vapor

// ============================================================
// MARK: - PasswordService
// ============================================================

protocol PasswordService: Sendable {
    /// Generate salt + hash. Returns (hash, salt)
    func hash(_ plaintext: String) throws -> (hash: String, salt: String)
    /// Verifikasi plaintext terhadap stored hash + salt
    func verify(_ plaintext: String, hash: String, salt: String) throws -> Bool
    /// Minimal 8 karakter, ada huruf + angka
    func validate(_ password: String) throws
}

// ============================================================
// MARK: - TokenService
// ============================================================

struct TokenPair {
    let accessToken: String
    let refreshToken: String    // raw token — hash-nya yang disimpan di DB
    let refreshTokenHash: String
    let accessTokenExpiresIn: Int   // detik
    let accessTokenExpiresAt: Date
    let refreshTokenExpiresAt: Date
}

protocol TokenService: Sendable {
    func generateTokenPair(userID: UUID, sessionID: UUID) throws -> TokenPair
    func verifyAccessToken(_ token: String) throws -> UUID    // returns userID
}

// ============================================================
// MARK: - WebAuthnService
// ============================================================

struct WebAuthnChallenge {
    let challenge: String   // base64url random bytes — simpan di Redis/cache sementara
    let rpID: String
    let rpName: String
}

struct WebAuthnRegistrationVerification {
    let credentialID: String        // base64url
    let publicKey: String           // COSE base64url
    let aaguid: String?
    let signCount: Int
    let attestationType: String?
    let transports: [String]?
}

struct WebAuthnAssertionVerification {
    let newSignCount: Int
}

protocol WebAuthnService: Sendable {
    func generateChallenge() throws -> WebAuthnChallenge
    /// Verifikasi attestation dari registration — throws jika gagal
    func verifyRegistration(
        challenge: String,
        clientDataJSON: String,
        attestationObject: String,
        expectedRpID: String
    ) throws -> WebAuthnRegistrationVerification

    /// Verifikasi assertion dari authentication — throws jika gagal
    func verifyAssertion(
        challenge: String,
        credentialID: String,
        clientDataJSON: String,
        authenticatorData: String,
        signature: String,
        publicKey: String,
        storedSignCount: Int,
        expectedRpID: String
    ) throws -> WebAuthnAssertionVerification
}

// ============================================================
// MARK: - ChallengeStore
// ============================================================
// Redis-backed temporary store untuk WebAuthn challenge.
// Challenge harus expire — default 5 menit.

protocol ChallengeStore: Sendable {
    func store(challenge: String, for key: String, ttl: Int) async throws
    func consume(for key: String) async throws -> String?   // nil jika sudah expired/tidak ada
}