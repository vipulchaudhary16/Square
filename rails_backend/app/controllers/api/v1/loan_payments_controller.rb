module Api
  module V1
    class LoanPaymentsController < ApplicationController
      before_action :set_loan

      def index
        render json: serialize_payments(@loan.loan_payments.order(paid_at: :desc))
      end

      def create
        return render json: { error: "Forbidden" }, status: :forbidden unless @loan.lender_for?(current_user.id)
        return render json: { error: "Loan is already settled" }, status: :unprocessable_entity if @loan.status == "PAID"

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

        contact_name = @loan.contact.name
        category = current_user.categories.find_or_initialize_by(name: "Interest Income")
        category.applies_to = ["income"]
        category.save! if category.new_record?

        income = current_user.incomes.find_or_initialize_by(source: "Interest on loan: #{contact_name}")
        income.assign_attributes(
          amount:      calc[:accrued_interest],
          date:        Date.today,
          category_id: category.id
        )
        income.save!
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
