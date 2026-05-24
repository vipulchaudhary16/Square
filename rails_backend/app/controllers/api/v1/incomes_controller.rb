module Api
  module V1
    class IncomesController < ApplicationController
      before_action :set_income, only: [:show, :update, :destroy, :comments]

      def index
        render json: current_user.incomes.includes(:category).order(date: :desc).map { |r| serialize(r) }
      end

      def show
        @logs     = @income.activity_logs.includes(:user).order(created_at: :desc)
        @comments = @income.comments.includes(:user).order(created_at: :asc)
        user_ids  = [@income.user_id, *@logs.map(&:user_id), *@comments.map(&:user_id)]
        render json: {
          income:   serialize(@income),
          logs:     serialize_logs(@logs),
          comments: serialize_comments(@comments),
          users:    build_user_map(user_ids)
        }
      end

      def create
        category = current_user.categories.find_by(id: params[:category_id]) ||
                   current_user.categories.find_by(name: "General")
        income = current_user.incomes.create!(
          source:      params[:source],
          amount:      params[:amount],
          category_id: category.id,
          date:        params[:date],
          description: params[:description]
        )
        render json: serialize(income), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        changes = track_changes(@income, [:source, :amount, :category_id, :date, :description], params)
        if @income.update(income_params.slice(*income_params.keys.map(&:to_sym).select { |k| params[k].present? }))
          log_activity(loggable: @income, action: "UPDATE", details: changes.join(", ")) if changes.any?
          render json: { message: "Income updated successfully" }
        else
          render json: { error: @income.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @income.destroy!
        render json: { message: "Income deleted successfully" }
      end

      def comments
        comment = Comment.create!(commentable: @income, user: current_user, text: params[:text])
        log_activity(loggable: @income, action: "COMMENT", details: params[:text])
        render json: serialize_comment(comment), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_income
        @income = current_user.incomes.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Income not found" }, status: :not_found
      end

      def income_params
        params.permit(:source, :amount, :category_id, :date, :description)
      end

      def serialize(r)
        { id: r.id.to_s, user_id: r.user_id.to_s, source: r.source, amount: r.amount.to_f,
          category_id: r.category_id.to_s, category_name: r.category&.name || "",
          date: r.date.iso8601, description: r.description, created_at: r.created_at.iso8601 }
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

      def track_changes(record, fields, params)
        fields.filter_map do |f|
          next unless params[f].present?
          old_val = record.send(f)
          new_val = params[f]
          "#{f}: #{old_val} → #{new_val}" if old_val.to_s != new_val.to_s
        end
      end
    end
  end
end
