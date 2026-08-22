module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request,
                          only: [:signup, :login, :refresh, :forgot_password, :reset_password]

      def signup
        user = User.sign_up!(params)
        if user.persisted?
          session = SessionService.issue_for(user)
          render json: session.merge(user: user.api_json), status: :created
        else
          render json: { error: user.errors.full_messages.first }, status: :bad_request
        end
      end

      def login
        user = User.authenticate_login(email: params[:email], password: params[:password])
        if user
          session = SessionService.issue_for(user)
          render json: session.merge(user: user.api_json)
        else
          render json: { error: "Invalid credentials" }, status: :unauthorized
        end
      end

      def refresh
        session = SessionService.refresh(params[:refresh_token])
        render json: session
      rescue SessionService::Invalid, SessionService::Reused => e
        render json: { error: e.message }, status: :unauthorized
      end

      def logout
        SessionService.revoke(params[:refresh_token]) if params[:refresh_token].present?
        SessionService.revoke_access_token(current_access_token_jti, current_access_token_exp)
        head :no_content
      end

      def logout_all
        SessionService.revoke_all_for(current_user)
        SessionService.revoke_access_token(current_access_token_jti, current_access_token_exp)
        head :no_content
      end

      def forgot_password
        user = User.find_by("lower(email) = ?", params[:email]&.downcase)
        user&.initiate_password_reset!
        render json: { message: "If an account with that email exists, we sent a reset link" }
      end

      def reset_password
        User.reset_password!(token: params[:token], new_password: params[:password])
        render json: { message: "Password reset successfully" }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Invalid or expired token" }, status: :bad_request
      end

      def me
        render json: current_user.api_json
      end
    end
  end
end
