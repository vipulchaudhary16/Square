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
      @current_user = User.find(decoded[:user_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :unauthorized
    rescue StandardError => e
      render json: { error: e.message }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end
end
