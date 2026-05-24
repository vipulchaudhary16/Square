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

  def build_user_map(user_ids)
    User.where(id: user_ids.uniq.compact).each_with_object({}) do |u, h|
      h[u.id.to_s] = u.display_name
    end
  end

  def log_activity(loggable:, action:, details: "")
    ActivityLog.create!(loggable: loggable, user: current_user, action: action, details: details)
  end
end
