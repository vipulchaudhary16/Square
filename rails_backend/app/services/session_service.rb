require "digest"

# Issues and rotates refresh tokens for a login session, entirely in Redis
# (no Postgres table — session state is ephemeral, TTL'd data).
#
# Each login/signup starts a "family": a chain of refresh tokens where only
# one token is ever valid at a time. Refreshing rotates to a new token and
# tombstones the old one; presenting a tombstoned (already-rotated) token
# again is treated as theft and kills the whole family immediately.
class SessionService
  class Invalid < StandardError; end
  class Reused < StandardError; end

  REFRESH_TTL          = Integer(ENV.fetch("REFRESH_TOKEN_TTL_DAYS", 30)).days
  REFRESH_ABSOLUTE_TTL = Integer(ENV.fetch("REFRESH_ABSOLUTE_TTL_DAYS", 90)).days

  def self.issue_for(user)
    new.issue_for(user)
  end

  def self.refresh(raw_token)
    new.refresh(raw_token)
  end

  def self.revoke(raw_token)
    new.revoke(raw_token)
  end

  def self.revoke_all_for(user)
    new.revoke_all_for(user)
  end

  def issue_for(user)
    family_id = SecureRandom.uuid
    pair = mint(user.id, family_id, created_at: Time.current.to_i)
    RedisPool.with { |r| r.sadd("user_sessions:#{user.id}", family_id) }
    pair
  end

  def refresh(raw_token)
    hash = hash_token(raw_token)

    session = RedisPool.with { |r| r.hgetall("session:#{hash}") }
    raise Invalid, "Unknown or expired refresh token" if session.blank?

    if session["status"] == "rotated"
      revoke_family(session["family_id"], session["user_id"])
      raise Reused, "Refresh token was already used — session revoked"
    end

    created_at = session["created_at"].to_i
    if created_at > 0 && Time.current.to_i - created_at > REFRESH_ABSOLUTE_TTL.to_i
      revoke_family(session["family_id"], session["user_id"])
      raise Invalid, "Session exceeded its maximum lifetime"
    end

    RedisPool.with { |r| r.hset("session:#{hash}", "status", "rotated") }
    mint(session["user_id"], session["family_id"], created_at: created_at)
  end

  def revoke(raw_token)
    hash = hash_token(raw_token)
    session = RedisPool.with { |r| r.hgetall("session:#{hash}") }
    return if session.blank?

    revoke_family(session["family_id"], session["user_id"])
  end

  def revoke_all_for(user)
    family_ids = RedisPool.with { |r| r.smembers("user_sessions:#{user.id}") }
    family_ids.each { |family_id| revoke_family(family_id, user.id) }
    RedisPool.with { |r| r.del("user_sessions:#{user.id}") }
  end

  # Adds this access token's jti to the short-lived denylist so it stops
  # working immediately, instead of drifting until its natural expiry.
  def self.revoke_access_token(jti, exp)
    return if jti.blank?

    ttl = [exp.to_i - Time.current.to_i, 1].max
    RedisPool.with { |r| r.set("revoked_jti:#{jti}", 1, ex: ttl) }
  end

  private

  def mint(user_id, family_id, created_at:)
    access_token = JwtService.encode(user_id: user_id.to_s)
    refresh_token = SecureRandom.urlsafe_base64(32)
    hash = hash_token(refresh_token)

    RedisPool.with do |r|
      r.multi do |tx|
        tx.hset(
          "session:#{hash}",
          "user_id", user_id.to_s,
          "family_id", family_id,
          "status", "active",
          "created_at", created_at
        )
        tx.expire("session:#{hash}", REFRESH_TTL.to_i)
        tx.set("family:#{family_id}:current", hash, ex: REFRESH_TTL.to_i)
      end
    end

    { access_token: access_token, refresh_token: refresh_token }
  end

  def revoke_family(family_id, user_id)
    RedisPool.with do |r|
      current_hash = r.get("family:#{family_id}:current")
      r.del("session:#{current_hash}") if current_hash
      r.del("family:#{family_id}:current")
      r.srem("user_sessions:#{user_id}", family_id) if user_id
    end
  end

  def hash_token(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end
end
