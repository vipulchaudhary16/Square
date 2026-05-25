module Api
  module V1
    class LoanPaymentsController < ApplicationController
      before_action :set_loan

      def index
        render json: serialize_payments(@loan.loan_payments.order(paid_at: :desc))
      end

      def create
        return render json: { error: "Forbidden" }, status: :forbidden unless @loan.lender_for?(current_user.id)

        paid_at = params[:paid_at].present? ? Time.zone.parse(params[:paid_at]) : Time.current
        payment = @loan.loan_payments.create!(amount: params[:amount], paid_at: paid_at, note: params[:note])

        update_loan_status
        maybe_create_interest_income if ActiveModel::Type::Boolean.new.cast(params[:add_interest_to_income])

        calc = InterestCalculatorService.new(@loan.reload).call
        render json: {
          payment:  serialize_payment(payment),
          loan:     serialize_loan(@loan, calc)
        }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_loan
        @loan = Loan.for_user(current_user.id).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Loan not found" }, status: :not_found
      end

      def update_loan_status
        total_paid = @loan.loan_payments.sum(:amount)
        if total_paid >= @loan.amount
          @loan.update!(status: "PAID")
        elsif total_paid > 0
          @loan.update!(status: "PARTIAL")
        end
      end

      def maybe_create_interest_income
        calc = InterestCalculatorService.new(@loan).call
        return unless calc[:accrued_interest] > 0

        category = current_user.categories.find_or_create_by!(name: "Interest Income") do |c|
          c.applies_to = ["income"]
        end
        current_user.incomes.create!(
          source:      "Interest on loan: #{@loan.contact.name}",
          amount:      calc[:accrued_interest],
          date:        Date.today,
          category_id: category.id
        )
      end

      def serialize_payments(payments)
        payments.map { |p| serialize_payment(p) }
      end

      def serialize_payment(p)
        { id: p.id.to_s, loan_id: p.loan_id.to_s,
          amount: p.amount.to_f, paid_at: p.paid_at.iso8601,
          note: p.note, created_at: p.created_at.iso8601 }
      end

      def serialize_loan(l, calc)
        { id: l.id.to_s, status: l.status,
          outstanding: calc[:outstanding],
          accrued_interest: calc[:accrued_interest],
          total_due: calc[:total_due] }
      end
    end
  end
end
