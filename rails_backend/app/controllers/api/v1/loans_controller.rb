module Api
  module V1
    class LoansController < ApplicationController
      before_action :set_loan, only: [:show, :update, :destroy, :comments]

      def index
        render json: current_user.loans.includes(:category).order(date: :desc).map { |r| serialize(r) }
      end

      def show
        @logs     = @loan.activity_logs.includes(:user).order(created_at: :desc)
        @comments = @loan.comments.includes(:user).order(created_at: :asc)
        user_ids  = [@loan.user_id, *@logs.map(&:user_id), *@comments.map(&:user_id)]
        render json: {
          loan:     serialize(@loan),
          logs:     serialize_logs(@logs),
          comments: serialize_comments(@comments),
          users:    build_user_map(user_ids)
        }
      end

      def create
        category = current_user.categories.find_by(id: params[:category_id])
        loan = current_user.loans.create!(
          loan_params.merge(category_id: category&.id)
        )
        render json: serialize(loan), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        changes = []
        [:counterparty_name, :loan_type, :amount, :date, :due_date, :status, :description].each do |f|
          next unless params[f].present?
          old_val = @loan.send(f)
          new_val = params[f]
          changes << "#{f}: #{old_val} → #{new_val}" if old_val.to_s != new_val.to_s
        end
        if @loan.update(loan_params)
          log_activity(loggable: @loan, action: "UPDATE", details: changes.join(", ")) if changes.any?
          render json: { message: "Loan updated successfully" }
        else
          render json: { error: @loan.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @loan.destroy!
        render json: { message: "Loan deleted successfully" }
      end

      def comments
        comment = Comment.create!(commentable: @loan, user: current_user, text: params[:text])
        log_activity(loggable: @loan, action: "COMMENT", details: params[:text])
        render json: serialize_comment(comment), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_loan
        @loan = current_user.loans.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Loan not found" }, status: :not_found
      end

      def loan_params
        params.permit(:counterparty_name, :loan_type, :amount, :date, :due_date, :status, :description, :category_id)
      end

      def serialize(r)
        { id: r.id.to_s, user_id: r.user_id.to_s, counterparty_name: r.counterparty_name,
          type: r.loan_type, amount: r.amount.to_f, date: r.date.iso8601,
          due_date: r.due_date&.iso8601, status: r.status, description: r.description,
          category_id: r.category_id.to_s, category_name: r.category&.name || "",
          created_at: r.created_at.iso8601 }
      end

      def serialize_logs(logs)
        logs.map { |l| { id: l.id.to_s, user_id: l.user_id.to_s, action: l.action, details: l.details, created_at: l.created_at.iso8601 } }
      end

      def serialize_comments(comments)
        comments.map { |c| serialize_comment(c) }
      end

      def serialize_comment(c)
        { id: c.id.to_s, user_id: c.user_id.to_s, text: c.text, created_at: c.created_at.iso8601 }
      end
    end
  end
end
