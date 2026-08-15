module Api
  module V1
    class LoansController < ApplicationController
      before_action :set_loan, only: [:show, :update, :destroy, :comments, :confirmation]
      before_action :require_lender,  only: [:update, :destroy]
      before_action :require_borrower, only: [:confirmation]

      def index
        loans = Loan.for_user(current_user.id)
                    .includes(:contact, :category, :loan_payments)
                    .order(date: :desc)
        render json: loans.map { |l| l.api_json(current_user: current_user) }
      end

      def show
        logs     = @loan.activity_logs.includes(:user).order(created_at: :desc)
        comments = @loan.comments.includes(:user).order(created_at: :asc)
        calc     = InterestCalculatorService.new(@loan).call
        render json: {
          loan:              @loan.api_json(calc: calc, current_user: current_user),
          payments:          @loan.loan_payments.order(paid_at: :desc).map(&:api_json),
          interest_timeline: calc[:interest_timeline],
          logs:              logs.map { |l| l.api_json(include_user: false) },
          comments:          comments.map(&:api_json)
        }
      end

      def create
        loan = Loan.create_for_lender!(lender: current_user, contact_id: params[:contact_id], attrs: loan_params)
        render json: loan.api_json(current_user: current_user), status: :created
      rescue ArgumentError => e
        render json: { error: e.message }, status: :bad_request
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Contact not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        if @loan.apply_update!(loan_params, current_user: current_user)
          render json: { message: "Loan updated" }
        else
          render json: { error: @loan.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @loan.destroy!
        render json: { message: "Loan deleted" }
      end

      def comments
        comment = Comment.create!(commentable: @loan, user: current_user, text: params[:text])
        ActivityLog.record!(loggable: @loan, user: current_user, action: "COMMENT", details: params[:text])
        render json: comment.api_json, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def confirmation
        if @loan.update_confirmation(params[:confirmation_status])
          render json: { message: "Confirmation updated", confirmation_status: @loan.confirmation_status }
        else
          render json: { error: @loan.errors.full_messages.first }, status: :bad_request
        end
      rescue ArgumentError => e
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

      def require_borrower
        return if @loan.borrower_user_id == current_user.id
        render json: { error: "Forbidden" }, status: :forbidden
      end

      def loan_params
        params.permit(:amount, :date, :due_date, :status, :description,
                      :category_id, :interest_mode, :interest_rate,
                      :interest_period, :interest_basis)
      end
    end
  end
end
