module Api
  module V1
    class IncomesController < ApplicationController
      before_action :set_income, only: [:show, :update, :destroy, :comments]

      def index
        render json: current_user.incomes.includes(:category).order(date: :desc).map(&:api_json)
      end

      def show
        logs     = @income.activity_logs.includes(:user).order(created_at: :desc)
        comments = @income.comments.includes(:user).order(created_at: :asc)
        user_ids = [@income.user_id, *logs.map(&:user_id), *comments.map(&:user_id)]
        render json: {
          income:   @income.api_json,
          logs:     logs.map(&:api_json),
          comments: comments.map(&:api_json),
          users:    User.display_name_map(user_ids)
        }
      end

      def create
        income = Income.create_for_user!(user: current_user, params: params)
        render json: income.api_json, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        if @income.apply_updates!(params, current_user: current_user)
          render json: { message: "Income updated successfully" }
        else
          render json: { error: @income.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @income.destroy!
        render json: { message: "Income deleted successfully" }
      end

      def comments
        comment = Comment.create!(commentable: @income, user: current_user, text: params[:text])
        ActivityLog.record!(loggable: @income, user: current_user, action: "COMMENT", details: params[:text])
        render json: comment.api_json, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_income
        @income = current_user.incomes.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Income not found" }, status: :not_found
      end
    end
  end
end
