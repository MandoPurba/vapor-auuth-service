import JWT
import Vapor

func configureJWT(_ app: Application) async {
    let jwtSecret = Environment.get("JWT_SECRET") ?? "dev-secret-change-me"
    if jwtSecret == "dev-secret-change-me" {
        app.logger.warning("JWT_SECRET is not set. Using insecure default; set JWT_SECRET in production.")
    }

    let hmacKey = HMACKey(from: jwtSecret)
    await app.jwt.keys.add(hmac: hmacKey, digestAlgorithm: .sha256)
}
