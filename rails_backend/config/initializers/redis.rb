require "connection_pool"
require "redis"

# Puma runs multi-threaded and a single Redis client isn't thread-safe, so
# every caller checks out its own connection from the pool for the duration
# of a block via RedisPool.with { |redis| ... }.
RedisPool = ConnectionPool.new(size: Integer(ENV.fetch("RAILS_MAX_THREADS", 5)), timeout: 5) do
  Redis.new(url: ENV.fetch("REDIS_URL"))
end
