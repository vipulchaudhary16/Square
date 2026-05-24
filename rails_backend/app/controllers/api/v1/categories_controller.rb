module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :set_category, only: [:update, :destroy]

      def index
        categories = current_user.categories
        categories = categories.where("? = ANY(applies_to)", params[:applies_to]) if params[:applies_to].present?
        render json: categories.order(:name).map { |c| serialize(c) }
      end

      def create
        category = current_user.categories.create!(
          name:        params[:name],
          applies_to:  Array(params[:applies_to]),
          is_standard: false
        )
        render json: serialize(category), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        if @category.is_standard
          render json: { error: "Standard categories cannot be renamed" }, status: :unprocessable_entity and return
        end

        attrs = {}
        attrs[:name]       = params[:name]       if params[:name].present?
        attrs[:applies_to] = Array(params[:applies_to]) if params[:applies_to].present?

        if attrs.empty?
          render json: { error: "No fields provided to update" }, status: :bad_request and return
        end

        if @category.update(attrs)
          render json: serialize(@category)
        else
          render json: { error: @category.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        if @category.is_standard
          render json: { error: "Standard categories cannot be deleted" }, status: :unprocessable_entity and return
        end

        other = current_user.categories.find_by(name: "Other")
        unless other
          render json: { error: "Cannot delete category: fallback 'Other' category is missing" }, status: :unprocessable_entity and return
        end

        ActiveRecord::Base.transaction do
          Expense.where(payer_id: current_user.id, category_id: @category.id).update_all(category_id: other.id)
          Income.where(user_id: current_user.id, category_id: @category.id).update_all(category_id: other.id)
          Budget.where(user_id: current_user.id, category_id: @category.id).update_all(category_id: other.id)
          @category.destroy!
        end

        render json: { message: "Category deleted. Records moved to 'Other'." }
      end

      private

      def set_category
        @category = current_user.categories.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Category not found" }, status: :not_found
      end

      def serialize(c)
        { id: c.id.to_s, name: c.name, applies_to: c.applies_to, is_standard: c.is_standard }
      end
    end
  end
end
