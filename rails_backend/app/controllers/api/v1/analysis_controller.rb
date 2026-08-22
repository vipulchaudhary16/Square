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
          spending: AnalysisService.summarize(expenses),
          income:   AnalysisService.summarize(incomes)
        }
      end
    end
  end
end
