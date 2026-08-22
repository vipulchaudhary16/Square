module Api
  module V1
    class AnalysisController < ApplicationController
      def show
        expenses = current_user.expenses_paid.where(group_id: nil).includes(:category)
        expenses = expenses.where("date >= ?", params[:start_date]) if params[:start_date].present?
        expenses = expenses.where("date <= ?", params[:end_date]) if params[:end_date].present?

        incomes = current_user.incomes.includes(:category)
        incomes = incomes.where("date >= ?", params[:start_date]) if params[:start_date].present?
        incomes = incomes.where("date <= ?", params[:end_date]) if params[:end_date].present?

        render json: {
          spending: summarize(expenses),
          income:   summarize(incomes)
        }
      end

      private

      def summarize(scope)
        records = scope.to_a
        total   = records.sum(&:amount).to_f

        by_category = records.group_by(&:category).map do |category, items|
          amount = items.sum(&:amount).to_f
          {
            category_id:    category&.id.to_s,
            category_name:  category&.name || "Uncategorized",
            category_color: category&.color,
            amount:         amount,
            percent:        total > 0 ? (amount / total * 100).round(1) : 0.0
          }
        end.sort_by { |c| -c[:amount] }

        { total: total, count: records.size, by_category: by_category }
      end
    end
  end
end
