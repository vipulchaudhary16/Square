module Api
  module V1
    class ExpensesController < ApplicationController
      before_action :set_expense, only: [:show, :update, :destroy, :comments]

      def index
        expenses = Expense
          .accessible_to(current_user)
          .with_filters(params)
          .with_sort(params)
          .includes(:payer, :group, :category, :expense_splits, :expense_participants)

        if params[:limit].present?
          page  = (params[:page] || 1).to_i
          limit = params[:limit].to_i
          total = expenses.count
          data  = expenses.offset((page - 1) * limit).limit(limit)
          render json: { data: serialize_list(data), total: total, page: page, limit: limit }
        else
          render json: serialize_list(expenses)
        end
      end

      def show
        logs     = @expense.activity_logs.includes(:user).order(created_at: :desc)
        comments = @expense.comments.includes(:user).order(created_at: :asc)
        user_ids = [
          @expense.payer_id,
          *@expense.expense_splits.map(&:user_id),
          *@expense.expense_participants.map(&:user_id),
          *logs.map(&:user_id),
          *comments.map(&:user_id)
        ]
        render json: {
          expense:  serialize_list([@expense]).first,
          logs:     logs.map { |l| { id: l.id.to_s, user_id: l.user_id.to_s, action: l.action, details: l.details, created_at: l.created_at.iso8601 } },
          comments: comments.map { |c| { id: c.id.to_s, user_id: c.user_id.to_s, text: c.text, created_at: c.created_at.iso8601 } },
          users:    build_user_map(user_ids)
        }
      end

      def create
        category = current_user.categories.find_by(id: params[:category_id]) ||
                   current_user.categories.find_by(name: "General")

        participant_ids = params[:participants] || [current_user.id.to_s]
        raw_splits      = params[:splits]&.to_unsafe_h || {}
        splits_calculated = ExpenseSplitCalculator.calculate(
          params[:amount].to_f, params[:split_type], participant_ids, raw_splits
        )

        expense = Expense.new(
          description: params[:description],
          amount:      params[:amount],
          category_id: category.id,
          date:        params[:date] || Time.current,
          payer_id:    current_user.id,
          group_id:    params[:group_id],
          split_type:  params[:split_type] || "EQUAL"
        )

        Expense.transaction do
          expense.save!
          participant_ids.each { |uid| ExpenseParticipant.create!(expense: expense, user_id: uid) }
          splits_calculated.each { |uid, amt| ExpenseSplit.create!(expense: expense, user_id: uid, amount: amt) }
          log_activity(loggable: expense, action: "CREATE", details: "Expense created: #{expense.description}")
        end

        render json: { message: "Expense created successfully", expense: { id: expense.id.to_s } }, status: :created
      rescue ArgumentError => e
        render json: { error: e.message }, status: :bad_request
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        changes = []

        if params[:category_id].present?
          new_cat = current_user.categories.find_by(id: params[:category_id])
          if new_cat && new_cat.id != @expense.category_id
            changes << "category: #{@expense.category.name} → #{new_cat.name}"
            @expense.category_id = new_cat.id
          end
        end

        [:description, :amount, :date, :split_type].each do |field|
          next unless params[field].present?
          old_val = @expense.send(field)
          new_val = params[field]
          if old_val.to_s != new_val.to_s
            changes << "#{field}: #{old_val} → #{new_val}"
            @expense.assign_attributes(field => new_val)
          end
        end

        if @expense.save
          log_activity(loggable: @expense, action: "UPDATE", details: changes.join(", ")) if changes.any?
          render json: { message: "Expense updated successfully" }
        else
          render json: { error: @expense.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @expense.destroy!
        render json: { message: "Expense deleted successfully" }
      end

      def comments
        comment = Comment.create!(commentable: @expense, user: current_user, text: params[:text])
        log_activity(loggable: @expense, action: "COMMENT", details: params[:text])
        render json: { id: comment.id.to_s, user_id: comment.user_id.to_s, text: comment.text, created_at: comment.created_at.iso8601 }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_expense
        @expense = Expense.accessible_to(current_user)
                          .includes(:category, :expense_splits, :expense_participants)
                          .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Expense not found" }, status: :not_found
      end

      def serialize_list(expenses)
        expenses.map do |e|
          {
            id:            e.id.to_s,
            description:   e.description,
            amount:        e.amount.to_f,
            category_id:   e.category_id.to_s,
            category_name: e.category&.name || "",
            date:          e.date.iso8601,
            payer_id:      e.payer_id.to_s,
            payer_name:    e.payer.display_name,
            group_id:      e.group_id&.to_s,
            group_name:    e.group&.name,
            split_type:    e.split_type,
            participants:  e.expense_participants.map { |p| p.user_id.to_s },
            splits:        e.expense_splits.each_with_object({}) { |s, h| h[s.user_id.to_s] = s.amount.to_f },
            created_at:    e.created_at.iso8601
          }
        end
      end
    end
  end
end
