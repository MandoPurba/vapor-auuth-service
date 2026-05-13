import Vapor

// ============================================================
// MARK: - Register
// ============================================================

struct RegisterRequestDTO: Content {
    let email: String
    let password: String
    let displayName: String?
    let deviceName: String
    let deviceType: String      // phone | tablet | desktop | watch
    let platform: String        // ios | android | web
    let osVersion: String?
    let appVersion: String?
    let deviceFingerprint: String
}

// ============================================================
// MARK: - Login
// ============================================================

struct LoginRequestDTO: Content {
    let email: String
    let password: String
    let deviceFingerprint: String
    let ipAddress: String?
    let userAgent: String?
}

// ============================================================
// MARK: - Biometric Registration
// ============================================================

/// Step 1 — client meminta challenge dari server
struct BiometricRegisterChallengeRequestDTO: Content {
    let userID: UUID
}

struct BiometricRegisterChallengeResponseDTO: Content {
    let challenge: String       // base64url random bytes
    let rpID: String            // relying party ID (domain)
    let rpName: String
    let userID: String          // base64url encoded user UUID
    let userName: String        // email
}

/// Step 2 — client mengirim hasil attestation
struct BiometricRegisterRequestDTO: Content {
    let userID: UUID
    let deviceID: UUID
    let credentialID: String            // base64url
    let clientDataJSON: String          // base64url
    let attestationObject: String       // base64url
    let deviceName: String
    let transports: [String]?
}

// ============================================================
// MARK: - Biometric Authentication
// ============================================================

/// Step 1 — client meminta challenge
struct BiometricAuthChallengeRequestDTO: Content {
    let credentialID: String    // hint untuk server memilih credential yang tepat
}

struct BiometricAuthChallengeResponseDTO: Content {
    let challenge: String       // base64url
    let rpID: String
    let allowedCredentialIDs: [String]  // base64url list
}

/// Step 2 — client mengirim hasil assertion
struct BiometricAuthRequestDTO: Content {
    let credentialID: String            // base64url
    let clientDataJSON: String          // base64url
    let authenticatorData: String       // base64url
    let signature: String               // base64url
    let userHandle: String?             // base64url (optional, dikirim oleh authenticator)
    let ipAddress: String?
    let userAgent: String?
}

// ============================================================
// MARK: - Refresh Token
// ============================================================

struct RefreshTokenRequestDTO: Content {
    let refreshToken: String    // raw token (belum di-hash)
}

// ============================================================
// MARK: - Shared Responses
// ============================================================

/// Dipakai oleh Register, Login, BiometricAuth, dan RefreshToken
struct AuthResponseDTO: Content {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int          // detik hingga access token expired
    let user: UserResponseDTO
    let session: SessionResponseDTO
}

struct UserResponseDTO: Content {
    let id: UUID
    let email: String
    let displayName: String?
    let avatarURL: String?
    let isEmailVerified: Bool
    let createdAt: Date?

    init(from user: User) {
        self.id = user.id!
        self.email = user.email
        self.displayName = user.displayName
        self.avatarURL = user.avatarURL
        self.isEmailVerified = user.isEmailVerified
        self.createdAt = user.createdAt
    }
}

struct SessionResponseDTO: Content {
    let id: UUID
    let deviceID: UUID
    let authMethod: String
    let expiresAt: Date
    let createdAt: Date?

    init(from session: Session) {
        self.id = session.id!
        self.deviceID = session.$device.id
        self.authMethod = session.authMethod
        self.expiresAt = session.expiresAt
        self.createdAt = session.createdAt
    }
}

struct BiometricCredentialResponseDTO: Content {
    let id: UUID
    let credentialID: String
    let deviceID: UUID
    let aaguid: String?
    let transports: [String]?
    let createdAt: Date?

    init(from credential: BiometricCredential) {
        self.id = credential.id!
        self.credentialID = credential.credentialId
        self.deviceID = credential.$device.id
        self.aaguid = credential.aaguid
        self.transports = credential.transports
        self.createdAt = credential.createdAt
    }
}