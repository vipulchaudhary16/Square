Rails.application.config.middleware.use(Rack::Attack)

class Rack::Attack
  Rack::Attack.enabled = !Rails.env.test?
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("REDIS_URL"))

  throttle("auth/login-signup/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.path.in?(%w[/api/auth/login /api/auth/signup]) && req.post?
  end

  throttle("auth/login/email", limit: 5, period: 1.minute) do |req|
    req.params["email"].to_s.downcase if req.path == "/api/auth/login" && req.post?
  end

  throttle("auth/refresh/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path == "/api/auth/refresh" && req.post?
  end

  throttle("invites/accept/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path.match?(%r{\A/invites/[^/]+/accept\z}) && req.post?
  end
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
  Rails.logger.warn("[rack-attack] throttled #{payload[:request].path} from #{payload[:request].ip}")
end
