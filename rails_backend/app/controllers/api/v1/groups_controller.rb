module Api
  module V1
    class GroupsController < ApplicationController
      before_action :set_group, only: [:show, :invite, :members, :group_expenses, :settle]

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
        @group.invite!(params[:email])
        render json: { message: "Invitation sent to #{params[:email]}" }
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def join
        invite = GroupInvite.accept!(token: params[:token], current_user: current_user)
        unless invite
          return render json: { error: "Invalid or expired invitation token" }, status: :bad_request
        end
        render json: { message: "Joined group successfully", group_id: invite.group_id.to_s }
      end

      def members
        user = User.find(params[:user_id])
        @group.add_member!(user)
        render json: { message: "Member added", user: user.member_json }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
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
    end
  end
end
