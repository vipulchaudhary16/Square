module Api
  module V1
    class BudgetsController < ApplicationController
      before_action :set_budget, only: [:update, :destroy]

      def index
        budgets = current_user.budgets.includes(:category)
        budgets = budgets.where(month: params[:month]) if params[:month].present?
        render json: budgets.joins(:category).order("categories.name").map { |b| serialize(b) }
      end

      def create
        category = current_user.categories.find_by(id: params[:category_id]) ||
                   current_user.categories.find_by(name: "General")
        budget = current_user.budgets.create!(
          category_id: category.id,
          amount:      params[:amount],
          month:       params[:month]
        )
        render json: serialize(budget), status: :created
      rescue ActiveRecord::RecordInvalid => e
        if e.message.include?("already been taken")
          render json: { error: "Budget for this category and month already exists" }, status: :conflict
        else
          render json: { error: e.message }, status: :bad_request
        end
      end

      def update
        if @budget.update(amount: params[:amount])
          render json: { message: "Budget updated successfully" }
        else
          render json: { error: @budget.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @budget.destroy!
        render json: { message: "Budget deleted successfully" }
      end

      private

      def set_budget
        @budget = current_user.budgets.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Budget not found" }, status: :not_found
      end

      def serialize(b)
        { id: b.id.to_s, user_id: b.user_id.to_s,
          category_id: b.category_id.to_s, category_name: b.category&.name || "",
          amount: b.amount.to_f, month: b.month, created_at: b.created_at.iso8601 }
      end
    end
  end
end
