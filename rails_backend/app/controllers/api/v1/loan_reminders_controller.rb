module Api
  module V1
    class LoanRemindersController < ApplicationController
      before_action :set_loan

      def create
        unless @loan.lender_for?(current_user.id)
          return render json: { error: "Forbidden" }, status: :forbidden
        end
        remind_at = params[:remind_at].present? ? Time.zone.parse(params[:remind_at]) : nil
        unless remind_at
          return render json: { error: "remind_at is required" }, status: :bad_request
        end
        reminder = @loan.loan_reminders.create!(
          set_by_user_id: current_user.id,
          remind_at:      remind_at,
          nudge_borrower: ActiveModel::Type::Boolean.new.cast(params[:nudge_borrower]) || false,
          via_push:       ActiveModel::Type::Boolean.new.cast(params[:via_push]) != false,
          via_sms:        ActiveModel::Type::Boolean.new.cast(params[:via_sms]) || false,
          via_email:      ActiveModel::Type::Boolean.new.cast(params[:via_email]) != false
        )
        render json: {
          id:             reminder.id.to_s,
          loan_id:        reminder.loan_id.to_s,
          remind_at:      reminder.remind_at.iso8601,
          nudge_borrower: reminder.nudge_borrower,
          created_at:     reminder.created_at.iso8601
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
    end
  end
end
