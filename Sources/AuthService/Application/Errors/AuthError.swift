import Vapor

// MARK: - AuthError

enum AuthError: AbortError {
    // Register
    case emailAlreadyExists
    case weakPassword

    // Login
    case invalidCredentials
    case accountInactive
    case accountLocked(until: Date)
    case emailNotVerified

    // Biometric
    case biometricCredentialNotFound
    case biometricSignCountInvalid   // sign count dari device < DB — kemungkinan cloning
    case biometricCredentialInactive
    case webAuthnChallengeMismatch
    case webAuthnVerificationFailed

    // Token
    case refreshTokenNotFound
    case refreshTokenRevoked
    case refreshTokenExpired
    case refreshTokenFamilyCompromised  // reuse detected — seluruh family di-revoke

    // Session
    case sessionNotFound
    case sessionExpired
    case sessionInactive

    // Device
    case deviceNotFound
    case deviceNotBelongToUser

    // General
    case userNotFound

    // MARK: AbortError conformance

    var status: HTTPResponseStatus {
        switch self {
        case .emailAlreadyExists:              return .conflict
        case .weakPassword:                    return .badRequest
        case .invalidCredentials:              return .unauthorized
        case .accountInactive:                 return .forbidden
        case .accountLocked:                   return .forbidden
        case .emailNotVerified:                return .forbidden
        case .biometricCredentialNotFound:     return .notFound
        case .biometricSignCountInvalid:       return .unauthorized
        case .biometricCredentialInactive:     return .forbidden
        case .webAuthnChallengeMismatch:       return .badRequest
        case .webAuthnVerificationFailed:      return .unauthorized
        case .refreshTokenNotFound:            return .unauthorized
        case .refreshTokenRevoked:             return .unauthorized
        case .refreshTokenExpired:             return .unauthorized
        case .refreshTokenFamilyCompromised:   return .unauthorized
        case .sessionNotFound:                 return .notFound
        case .sessionExpired:                  return .unauthorized
        case .sessionInactive:                 return .unauthorized
        case .deviceNotFound:                  return .notFound
        case .deviceNotBelongToUser:           return .forbidden
        case .userNotFound:                    return .notFound
        }
    }

    var reason: String {
        switch self {
        case .emailAlreadyExists:
            return "Email already registered."
        case .weakPassword:
            return "Password does not meet minimum requirements."
        case .invalidCredentials:
            return "Invalid email or password."
        case .accountInactive:
            return "Account is inactive. Please contact support."
        case .accountLocked(let until):
            let formatter = ISO8601DateFormatter()
            return "Account is temporarily locked until \(formatter.string(from: until))."
        case .emailNotVerified:
            return "Email address has not been verified."
        case .biometricCredentialNotFound:
            return "Biometric credential not found."
        case .biometricSignCountInvalid:
            return "Biometric authenticator signature counter is invalid. Credential may be compromised."
        case .biometricCredentialInactive:
            return "Biometric credential is inactive."
        case .webAuthnChallengeMismatch:
            return "WebAuthn challenge does not match."
        case .webAuthnVerificationFailed:
            return "WebAuthn signature verification failed."
        case .refreshTokenNotFound:
            return "Refresh token not found."
        case .refreshTokenRevoked:
            return "Refresh token has been revoked."
        case .refreshTokenExpired:
            return "Refresh token has expired."
        case .refreshTokenFamilyCompromised:
            return "Token reuse detected. All sessions for this token family have been revoked."
        case .sessionNotFound:
            return "Session not found."
        case .sessionExpired:
            return "Session has expired."
        case .sessionInactive:
            return "Session is no longer active."
        case .deviceNotFound:
            return "Device not found."
        case .deviceNotBelongToUser:
            return "Device does not belong to this user."
        case .userNotFound:
            return "User not found."
        }
    }
}