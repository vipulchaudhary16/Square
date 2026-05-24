module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: [:signup, :login, :forgot_password, :reset_password]

      def signup
        user = User.new(
          email:      params[:email],
          first_name: params[:first_name] || "",
          last_name:  params[:last_name]  || "",
          username:   params[:username],
          password:   params[:password]
        )
        if user.save
          CategorySeeder.seed(user)
          token = JwtService.encode({ user_id: user.id.to_s })
          render json: { token: token, user: user_json(user) }, status: :created
        else
          render json: { error: user.errors.full_messages.first }, status: :bad_request
        end
      end

      def login
        user = User.find_by("lower(email) = ?", params[:email]&.downcase)
        if user&.authenticate(params[:password])
          token = JwtService.encode({ user_id: user.id.to_s })
          render json: { token: token, user: user_json(user) }
        else
          render json: { error: "Invalid credentials" }, status: :unauthorized
        end
      end

      def forgot_password
        user = User.find_by("lower(email) = ?", params[:email]&.downcase)
        if user
          token = SecureRandom.hex(32)
          user.update!(reset_token: token, reset_token_expiry: 1.hour.from_now)
          UserMailer.password_reset(user, token).deliver_later
        end
        render json: { message: "If an account with that email exists, we sent a reset link" }
      end

      def reset_password
        user = User.find_by(reset_token: params[:token])
        if user.nil? || user.reset_token_expiry < Time.current
          render json: { error: "Invalid or expired token" }, status: :bad_request and return
        end
        user.update!(password: params[:password], reset_token: nil, reset_token_expiry: nil)
        render json: { message: "Password reset successfully" }
      end

      def me
        render json: user_json(current_user)
      end

      private

      def user_json(user)
        {
          id:         user.id.to_s,
          username:   user.username,
          email:      user.email,
          first_name: user.first_name,
          last_name:  user.last_name,
          created_at: user.created_at.iso8601
        }
      end
    end
  end
end
