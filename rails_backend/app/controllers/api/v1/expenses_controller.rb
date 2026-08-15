module Api
  module V1
    class ExpensesController < ApplicationController
      before_action :set_expense, only: [:show, :update, :destroy, :comments]

      def index
        expenses = Expense.for_index(current_user, params)

        if params[:limit].present?
          page  = (params[:page] || 1).to_i
          limit = params[:limit].to_i
          total = expenses.count
          data  = expenses.offset((page - 1) * limit).limit(limit)
          render json: { data: data.map(&:api_json), total: total, page: page, limit: limit }
        else
          render json: expenses.map(&:api_json)
        end
      end

      def show
        logs     = @expense.activity_logs.includes(:user).order(created_at: :desc)
        comments = @expense.comments.includes(:user).order(created_at: :asc)
        user_ids = [
          @expense.payer_id,
          *@expense.expense_splits.map(&:user_id),
          *@expense.expense_participants.map(&:user_id),
          *logs.map(&:user_id),
          *comments.map(&:user_id)
        ]
        render json: {
          expense:  @expense.api_json,
          logs:     logs.map(&:api_json),
          comments: comments.map(&:api_json),
          users:    User.display_name_map(user_ids)
        }
      end

      def create
        expense = Expense.create_with_splits!(user: current_user, params: params)
        render json: { message: "Expense created successfully", expense: { id: expense.id.to_s } }, status: :created
      rescue ArgumentError => e
        render json: { error: e.message }, status: :bad_request
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        if @expense.apply_updates!(params, current_user: current_user)
          render json: { message: "Expense updated successfully" }
        else
          render json: { error: @expense.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @expense.destroy!
        render json: { message: "Expense deleted successfully" }
      end

      def comments
        comment = Comment.create!(commentable: @expense, user: current_user, text: params[:text])
        ActivityLog.record!(loggable: @expense, user: current_user, action: "COMMENT", details: params[:text])
        render json: comment.api_json, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_expense
        @expense = Expense.accessible_to(current_user)
                          .includes(:category, :expense_splits, :expense_participants)
                          .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Expense not found" }, status: :not_found
      end
    end
  end
end
