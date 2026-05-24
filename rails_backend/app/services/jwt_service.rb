class JwtService
  ALGORITHM = "HS256"
  EXPIRY    = 72.hours

  def self.encode(payload)
    payload = payload.merge(exp: (Time.current + EXPIRY).to_i)
    JWT.encode(payload, secret, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, secret, true, { algorithm: ALGORITHM })
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::ExpiredSignature
    raise StandardError, "Token has expired"
  rescue JWT::DecodeError => e
    raise StandardError, "Invalid token: #{e.message}"
  end

  def self.secret
    ENV.fetch("JWT_SECRET") { raise "JWT_SECRET not configured" }
  end
end
