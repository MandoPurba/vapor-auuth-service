import NIOCore
import Redis
import Vapor

func configureRedis(_ app: Application) throws {
    app.redis.configuration = try RedisConfiguration(
        hostname: Environment.get("REDIS_HOST") ?? "localhost",
        port: Environment.get("REDIS_PORT").flatMap(Int.init(_:)) ?? 6379,
        password: Environment.get("REDIS_PASSWORD") ?? nil,
        pool: RedisConfiguration.PoolOptions(
            maximumConnectionCount: RedisConnectionPoolSize.maximumActiveConnections(10),
            minimumConnectionCount: 0,
            connectionBackoffFactor: 2,
            initialConnectionBackoffDelay: .milliseconds(100),
            connectionRetryTimeout: nil,
            onUnexpectedConnectionClose: nil
        )
    )
}
