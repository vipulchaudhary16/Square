module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :set_category, only: [:update, :destroy]

      def index
        categories = current_user.categories
        categories = categories.where("? = ANY(applies_to)", params[:applies_to]) if params[:applies_to].present?
        render json: categories.order(:name).map(&:api_json)
      end

      def create
        category = current_user.categories.create!(
          name:        params[:name],
          applies_to:  Array(params[:applies_to]),
          is_standard: false
        )
        render json: category.api_json, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        if @category.is_standard
          return render json: { error: "Standard categories cannot be renamed" }, status: :unprocessable_entity
        end

        attrs = {}
        attrs[:name]       = params[:name]       if params[:name].present?
        attrs[:applies_to] = Array(params[:applies_to]) if params[:applies_to].present?
        return render json: { error: "No fields provided to update" }, status: :bad_request if attrs.empty?

        if @category.update(attrs)
          render json: @category.api_json
        else
          render json: { error: @category.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @category.destroy_with_reassignment!
        render json: { message: "Category deleted. Records moved to 'Other'." }
      rescue Category::ProtectedError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue Category::MissingFallbackError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def set_category
        @category = current_user.categories.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Category not found" }, status: :not_found
      end
    end
  end
end
