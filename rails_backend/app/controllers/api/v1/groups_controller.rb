module Api
  module V1
    class GroupsController < ApplicationController
      before_action :set_group, only: [:show, :invite, :group_invites, :group_expenses, :group_analysis, :settle]
      before_action :require_owner!, only: [:invite, :group_invites]

      def index
        groups = current_user.groups.includes(:created_by, :members)
        render json: groups.map(&:api_json)
      end

      def show
        members = @group.members
        debts   = @group.debts
        render json: {
          group:   @group.api_json,
          members: members.map(&:member_json),
          debts:   debts.map { |d| { from: d.from_id.to_s, to: d.to_id.to_s, amount: d.amount } }
        }
      end

      def create
        group = Group.create_with_owner!(name: params[:name], description: params[:description], user: current_user)
        render json: group.api_json, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def invite
        invite = @group.invite!(params[:email])
        render json: invite.api_json, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      rescue Group::AlreadyMemberError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def group_invites
        render json: @group.group_invites.order(created_at: :desc).map(&:api_json)
      end

      def join
        invite = GroupInvite.accept!(token: params[:token], current_user: current_user)
        unless invite
          return render json: { error: "Invalid or expired invitation token" }, status: :bad_request
        end
        render json: { message: "Joined group successfully", group_id: invite.group_id.to_s }
      end

      def group_expenses
        expenses = @group.expenses
          .with_filters(params)
          .with_sort(params)
          .includes(:payer, :category, :expense_splits, :expense_participants)
        items = expenses.map { |e| e.group_summary_json.merge(type: "expense") }

        if params[:search].blank?
          items += @group.settlements.includes(:user, :to_user).map(&:settlement_json)
        end

        items.sort_by! { |i| i[:date] }
        items.reverse! unless params[:sort_order] == "asc"
        render json: items
      end

      def group_analysis
        expenses      = @group.expenses.with_filters(params).includes(:category, :expense_splits, :expense_participants)
        your_expenses = expenses.merge(Expense.accessible_to(current_user))

        previous_expenses      = nil
        previous_your_expenses = nil
        if params[:compare_start_date].present? && params[:compare_end_date].present?
          compare_filters = {
            category_id: params[:category_id],
            search:      params[:search],
            start_date:  params[:compare_start_date],
            end_date:    params[:compare_end_date]
          }
          previous_expenses = @group.expenses.with_filters(compare_filters)
            .includes(:category, :expense_splits, :expense_participants)
          previous_your_expenses = previous_expenses.merge(Expense.accessible_to(current_user))
        end

        render json: {
          total_expense: AnalysisService.summarize(expenses, previous_scope: previous_expenses),
          your_share:    AnalysisService.summarize(
            your_expenses,
            value: ->(e) { e.split_for(current_user.id) },
            previous_scope: previous_your_expenses
          )
        }
      end

      def settle
        to_user = User.find(params[:to_user_id])
        @group.settle_debt!(from_user: current_user, to_user: to_user, amount: params[:amount])
        render json: { message: "Debt settled successfully" }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      rescue Group::DebtExceededError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue ArgumentError => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_group
        @group = current_user.groups.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Group not found" }, status: :not_found
      end

      def require_owner!
        return if @group && @group.created_by_id == current_user.id

        render json: { error: "Only the group admin can manage invitations" }, status: :forbidden
      end
    end
  end
end
