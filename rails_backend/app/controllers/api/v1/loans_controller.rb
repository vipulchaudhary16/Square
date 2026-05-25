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
        render json: loans.map { |l| serialize(l, InterestCalculatorService.new(l).call) }
      end

      def show
        calc     = InterestCalculatorService.new(@loan).call
        logs     = @loan.activity_logs.includes(:user).order(created_at: :desc)
        comments = @loan.comments.includes(:user).order(created_at: :asc)
        render json: {
          loan:              serialize(@loan, calc),
          payments:          serialize_payments(@loan.loan_payments.order(paid_at: :desc)),
          interest_timeline: calc[:interest_timeline],
          logs:              serialize_logs(logs),
          comments:          serialize_comments(comments)
        }
      end

      def create
        return render json: { error: "contact_id is required" }, status: :bad_request unless params[:contact_id].present?
        contact = current_user.owned_contacts.find(params[:contact_id])
        loan    = Loan.create!(loan_params.merge(
          lender_user_id:   current_user.id,
          contact_id:       contact.id,
          borrower_user_id: contact.linked_user_id
        ))
        render json: serialize(loan), status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Contact not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        changes = changed_fields
        if @loan.update(loan_params)
          log_activity(loggable: @loan, action: "UPDATE", details: changes.join(", ")) if changes.any?
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
        log_activity(loggable: @loan, action: "COMMENT", details: params[:text])
        render json: serialize_comment(comment), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def confirmation
        status = params[:confirmation_status]
        unless Loan::CONFIRMATION_STATUSES.include?(status)
          return render json: { error: "Invalid confirmation_status" }, status: :bad_request
        end
        if @loan.update(confirmation_status: status, confirmed_at: status == "confirmed" ? Time.current : nil)
          render json: { message: "Confirmation updated", confirmation_status: @loan.confirmation_status }
        else
          render json: { error: @loan.errors.full_messages.first }, status: :bad_request
        end
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

      def changed_fields
        fields = %i[amount date due_date status description interest_mode interest_rate]
        fields.filter_map do |f|
          next unless params[f].present?
          old = @loan.send(f)
          new_val = params[f]
          "#{f}: #{old} → #{new_val}" if old.to_s != new_val.to_s
        end
      end

      def serialize(l, calc = nil)
        calc ||= InterestCalculatorService.new(l).call
        {
          id:                  l.id.to_s,
          lender_user_id:      l.lender_user_id.to_s,
          borrower_user_id:    l.borrower_user_id&.to_s,
          contact_id:          l.contact_id.to_s,
          contact_name:        l.contact&.name || "",
          direction:           l.lender_for?(current_user.id) ? "lent" : "borrowed",
          amount:              l.amount.to_f,
          outstanding:         calc[:outstanding],
          accrued_interest:    calc[:accrued_interest],
          total_due:           calc[:total_due],
          date:                l.date.iso8601,
          due_date:            l.due_date&.iso8601,
          status:              l.status,
          confirmation_status: l.confirmation_status,
          interest_mode:       l.interest_mode,
          interest_rate:       l.interest_rate&.to_f,
          interest_period:     l.interest_period,
          interest_basis:      l.interest_basis,
          description:         l.description,
          category_id:         l.category_id&.to_s,
          category_name:       l.category&.name || "",
          created_at:          l.created_at.iso8601
        }
      end

      def serialize_logs(logs)
        logs.map { |l| { id: l.id.to_s, action: l.action, details: l.details, created_at: l.created_at.iso8601 } }
      end

      def serialize_comments(comments)
        comments.map { |c| serialize_comment(c) }
      end

      def serialize_comment(c)
        { id: c.id.to_s, user_id: c.user_id.to_s, text: c.text, created_at: c.created_at.iso8601 }
      end

      def serialize_payments(payments)
        payments.map do |p|
          {
            id:         p.id.to_s,
            loan_id:    p.loan_id.to_s,
            amount:     p.amount.to_f,
            paid_at:    p.paid_at.iso8601,
            note:       p.note,
            created_at: p.created_at.iso8601
          }
        end
      end
    end
  end
end
