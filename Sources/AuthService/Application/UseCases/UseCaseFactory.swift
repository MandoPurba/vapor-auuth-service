import Vapor

// ============================================================
// MARK: - UseCaseFactory
// ============================================================
// Cara pakai di configure.swift:
//
//   app.useCases = UseCaseFactory(
//       userRepo: PostgresUserRepository(),
//       credentialRepo: PostgresUserCredentialRepository(),
//       deviceRepo: PostgresUserDeviceRepository(),
//       sessionRepo: PostgresSessionRepository(),
//       refreshTokenRepo: PostgresRefreshTokenRepository(),
//       biometricRepo: PostgresBiometricCredentialRepository(),
//       auditLogRepo: PostgresAuditLogRepository(),
//       passwordService: BcryptPasswordService(),
//       tokenService: JWTTokenService(app: app),
//       webAuthnService: SwiftWebAuthnService(),
//       challengeStore: RedisChallengeStore(redis: app.redis),
//       rpID: Environment.get("WEBAUTHN_RP_ID") ?? "localhost",
//       rpName: Environment.get("WEBAUTHN_RP_NAME") ?? "AuthService"
//   )

struct UseCaseFactory: Sendable {

    let register: RegisterUseCase
    let login: LoginUseCase
    let biometricAuth: BiometricAuthUseCase
    let refreshToken: RefreshTokenUseCase

    init(
        userRepo: any UserRepository,
        credentialRepo: any UserCredentialRepository,
        deviceRepo: any UserDeviceRepository,
        sessionRepo: any SessionRepository,
        refreshTokenRepo: any RefreshTokenRepository,
        biometricRepo: any BiometricCredentialRepository,
        auditLogRepo: any AuditLogRepository,
        passwordService: any PasswordService,
        tokenService: any TokenService,
        webAuthnService: any WebAuthnService,
        challengeStore: any ChallengeStore,
        rpID: String,
        rpName: String
    ) {
        self.register = RegisterUseCase(
            userRepo: userRepo,
            credentialRepo: credentialRepo,
            deviceRepo: deviceRepo,
            sessionRepo: sessionRepo,
            refreshTokenRepo: refreshTokenRepo,
            auditLogRepo: auditLogRepo,
            passwordService: passwordService,
            tokenService: tokenService
        )

        self.login = LoginUseCase(
            userRepo: userRepo,
            credentialRepo: credentialRepo,
            deviceRepo: deviceRepo,
            sessionRepo: sessionRepo,
            refreshTokenRepo: refreshTokenRepo,
            auditLogRepo: auditLogRepo,
            passwordService: passwordService,
            tokenService: tokenService
        )

        self.biometricAuth = BiometricAuthUseCase(
            rpID: rpID,
            rpName: rpName,
            userRepo: userRepo,
            deviceRepo: deviceRepo,
            biometricRepo: biometricRepo,
            sessionRepo: sessionRepo,
            refreshTokenRepo: refreshTokenRepo,
            auditLogRepo: auditLogRepo,
            webAuthnService: webAuthnService,
            challengeStore: challengeStore,
            tokenService: tokenService
        )

        self.refreshToken = RefreshTokenUseCase(
            refreshTokenRepo: refreshTokenRepo,
            sessionRepo: sessionRepo,
            userRepo: userRepo,
            deviceRepo: deviceRepo,
            auditLogRepo: auditLogRepo,
            tokenService: tokenService
        )
    }
}

// ============================================================
// MARK: - Vapor Application Storage Key
// ============================================================

private struct UseCaseFactoryKey: StorageKey {
    typealias Value = UseCaseFactory
}

extension Application {
    var useCases: UseCaseFactory {
        get {
            guard let factory = storage[UseCaseFactoryKey.self] else {
                fatalError("UseCaseFactory not configured. Call app.useCases = UseCaseFactory(...) in configure.swift")
            }
            return factory
        }
        set {
            storage[UseCaseFactoryKey.self] = newValue
        }
    }
}

extension Request {
    var useCases: UseCaseFactory { application.useCases }
}