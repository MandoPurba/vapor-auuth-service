import Fluent
import Vapor

func configureMigrations(_ app: Application) {
    app.migrations.add(CreateAuthSchema())          // 1. buat schema auth
    app.migrations.add(CreateUsers())               // 2. tabel inti
    app.migrations.add(CreateUserCredentials())     // 3. bergantung pada users
    app.migrations.add(CreateUserDevices())         // 4. bergantung pada users
    app.migrations.add(CreateBiometricCredentials()) // 5. bergantung pada users + user_devices
    app.migrations.add(CreateSessions())            // 6. bergantung pada users + user_devices
    app.migrations.add(CreateRefreshTokens())       // 7. bergantung pada users + sessions
    app.migrations.add(CreateMfaMethods())          // 8. bergantung pada users
    app.migrations.add(CreateAuditLogs())           // 9. bergantung pada users + sessions + user_devices

}
