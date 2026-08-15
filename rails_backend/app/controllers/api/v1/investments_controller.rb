module Api
  module V1
    class InvestmentsController < ApplicationController
      before_action :set_investment, only: [:show, :update, :destroy, :comments]

      def index
        render json: current_user.investments.includes(:category).order(date: :desc).map(&:api_json)
      end

      def show
        logs     = @investment.activity_logs.includes(:user).order(created_at: :desc)
        comments = @investment.comments.includes(:user).order(created_at: :asc)
        user_ids = [@investment.user_id, *logs.map(&:user_id), *comments.map(&:user_id)]
        render json: {
          investment: @investment.api_json,
          logs:       logs.map(&:api_json),
          comments:   comments.map(&:api_json),
          users:      User.display_name_map(user_ids)
        }
      end

      def create
        investment = Investment.create_for_user!(user: current_user, params: params)
        render json: investment.api_json, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        if @investment.apply_updates!(params, current_user: current_user)
          render json: { message: "Investment updated successfully" }
        else
          render json: { error: @investment.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @investment.destroy!
        render json: { message: "Investment deleted successfully" }
      end

      def comments
        comment = Comment.create!(commentable: @investment, user: current_user, text: params[:text])
        ActivityLog.record!(loggable: @investment, user: current_user, action: "COMMENT", details: params[:text])
        render json: comment.api_json, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_investment
        @investment = current_user.investments.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Investment not found" }, status: :not_found
      end
    end
  end
end
