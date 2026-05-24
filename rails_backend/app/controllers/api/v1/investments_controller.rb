module Api
  module V1
    class InvestmentsController < ApplicationController
      before_action :set_investment, only: [:show, :update, :destroy, :comments]

      def index
        render json: current_user.investments.includes(:category).order(date: :desc).map { |r| serialize(r) }
      end

      def show
        @logs     = @investment.activity_logs.includes(:user).order(created_at: :desc)
        @comments = @investment.comments.includes(:user).order(created_at: :asc)
        user_ids  = [@investment.user_id, *@logs.map(&:user_id), *@comments.map(&:user_id)]
        render json: {
          investment: serialize(@investment),
          logs:       serialize_logs(@logs),
          comments:   serialize_comments(@comments),
          users:      build_user_map(user_ids)
        }
      end

      def create
        category = current_user.categories.find_by(id: params[:category_id])
        investment = current_user.investments.create!(
          investment_params.merge(category_id: category&.id)
        )
        render json: serialize(investment), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        changes = []
        [:name, :investment_type, :amount_invested, :current_value, :date, :description].each do |f|
          next unless params[f].present?
          old_val = @investment.send(f)
          new_val = params[f]
          changes << "#{f}: #{old_val} → #{new_val}" if old_val.to_s != new_val.to_s
        end
        if @investment.update(investment_params)
          log_activity(loggable: @investment, action: "UPDATE", details: changes.join(", ")) if changes.any?
          render json: { message: "Investment updated successfully" }
        else
          render json: { error: @investment.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @investment.destroy!
        render json: { message: "Investment deleted successfully" }
      end

      def comments
        comment = Comment.create!(commentable: @investment, user: current_user, text: params[:text])
        log_activity(loggable: @investment, action: "COMMENT", details: params[:text])
        render json: serialize_comment(comment), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_investment
        @investment = current_user.investments.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Investment not found" }, status: :not_found
      end

      def investment_params
        params.permit(:name, :investment_type, :amount_invested, :current_value, :date, :description, :category_id)
      end

      def serialize(r)
        { id: r.id.to_s, user_id: r.user_id.to_s, name: r.name, type: r.investment_type,
          amount_invested: r.amount_invested.to_f, current_value: r.current_value.to_f,
          date: r.date.iso8601, description: r.description,
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
