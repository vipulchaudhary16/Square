module Api
  module V1
    class LoanPaymentsController < ApplicationController
      before_action :set_loan
      before_action :require_lender, only: [:create]

      def index
        render json: @loan.loan_payments.order(paid_at: :desc).map(&:api_json)
      end

      def create
        payment = @loan.record_payment!(
          amount:                  params[:amount],
          paid_at:                 params[:paid_at].present? ? Time.zone.parse(params[:paid_at]) : Time.current,
          note:                    params[:note],
          add_interest_to_income:  ActiveModel::Type::Boolean.new.cast(params[:add_interest_to_income])
        )
        calc = InterestCalculatorService.new(@loan.reload).call
        render json: { payment: payment.api_json, loan: @loan.payment_summary_json(calc) }, status: :created
      rescue Loan::AlreadySettledError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_loan
        @loan = Loan.for_user(current_user.id).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Loan not found" }, status: :not_found
      end

      def require_lender
        return if @loan.lender_for?(current_user.id)
        render json: { error: "Forbidden" }, status: :forbidden
      end
    end
  end
end
