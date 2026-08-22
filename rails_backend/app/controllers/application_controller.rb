class ApplicationController < ActionController::API
  before_action :authenticate_request

  private

  def authenticate_request
    header = request.headers["Authorization"]
    token  = header&.split(" ")&.last

    unless token
      render json: { error: "Missing or malformed Authorization header" }, status: :unauthorized and return
    end

    begin
      decoded = JwtService.decode(token)
      if decoded[:jti].present? && RedisPool.with { |r| r.exists?("revoked_jti:#{decoded[:jti]}") }
        render json: { error: "Token has been revoked" }, status: :unauthorized and return
      end

      @current_user = User.find(decoded[:user_id])
      @current_jti = decoded[:jti]
      @current_exp = decoded[:exp]
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :unauthorized
    rescue StandardError => e
      render json: { error: e.message }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def current_access_token_jti
    @current_jti
  end

  def current_access_token_exp
    @current_exp
  end
end
