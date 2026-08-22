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

        previous_expenses = nil
        previous_incomes  = nil
        if params[:compare_start_date].present? && params[:compare_end_date].present?
          previous_expenses = current_user.expenses_paid.where(group_id: nil).includes(:category)
            .where("date >= ?", params[:compare_start_date]).where("date <= ?", params[:compare_end_date])
          previous_incomes = current_user.incomes.includes(:category)
            .where("date >= ?", params[:compare_start_date]).where("date <= ?", params[:compare_end_date])
        end

        render json: {
          spending: AnalysisService.summarize(expenses, previous_scope: previous_expenses),
          income:   AnalysisService.summarize(incomes, previous_scope: previous_incomes)
        }
      end
    end
  end
end
