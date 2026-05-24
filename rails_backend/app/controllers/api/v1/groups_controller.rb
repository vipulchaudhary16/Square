module Api
  module V1
    class GroupsController < ApplicationController
      before_action :set_group, only: [:show, :invite, :members, :group_expenses, :settle]

      def index
        groups = current_user.groups.includes(:created_by, :members)
        render json: groups.map { |g| serialize_group(g) }
      end

      def show
        @members = @group.members
        expenses = @group.expenses.includes(:expense_participants, :expense_splits)
        @debts   = DebtSettlementService.compute(expenses)
        render json: {
          group:   serialize_group(@group),
          members: @members.map { |m| serialize_user(m) },
          debts:   @debts.map { |d| { from: d.from_id.to_s, to: d.to_id.to_s, amount: d.amount } }
        }
      end

      def create
        group = Group.new(name: params[:name], description: params[:description] || "", created_by: current_user)
        Group.transaction do
          group.save!
          GroupMembership.create!(group: group, user: current_user)
        end
        render json: serialize_group(group), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def invite
        invite = GroupInvite.create!(
          group:      @group,
          email:      params[:email],
          token:      SecureRandom.hex(32),
          expires_at: 48.hours.from_now
        )
        UserMailer.group_invite(params[:email], @group, invite.token).deliver_later
        render json: { message: "Invitation sent to #{params[:email]}" }
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def join
        invite = GroupInvite.pending_valid.find_by(token: params[:token])
        unless invite
          render json: { error: "Invalid or expired invitation token" }, status: :bad_request and return
        end

        user = User.find_by("lower(email) = ?", invite.email.downcase) || current_user

        GroupInvite.transaction do
          GroupMembership.find_or_create_by!(group: invite.group, user: user)
          invite.update!(status: "accepted")
        end
        render json: { message: "Joined group successfully", group_id: invite.group_id.to_s }
      end

      def members
        user = User.find(params[:user_id])
        GroupMembership.find_or_create_by!(group: @group, user: user)
        render json: { message: "Member added", user: serialize_user(user) }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end

      def group_expenses
        expenses = @group.expenses
          .with_filters(params)
          .with_sort(params)
          .includes(:payer, :expense_splits, :expense_participants)
        render json: expenses.map { |e| serialize_expense(e) }
      end

      def settle
        to_user = User.find(params[:to_user_id])
        amount  = params[:amount].to_f

        expense = Expense.new(
          description: "Settlement",
          amount:      amount,
          category:    "Settlement",
          date:        Time.current,
          payer_id:    current_user.id,
          group_id:    @group.id,
          split_type:  "EXACT"
        )
        Expense.transaction do
          expense.save!
          ExpenseParticipant.create!(expense: expense, user: to_user)
          ExpenseSplit.create!(expense: expense, user: to_user, amount: amount)
          ActivityLog.create!(
            loggable: expense, user: current_user,
            action: "SETTLE",
            details: "#{current_user.display_name} settled #{amount} with #{to_user.display_name}"
          )
        end
        render json: { message: "Debt settled successfully", expense: { id: expense.id.to_s } }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end

      private

      def set_group
        @group = current_user.groups.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Group not found" }, status: :not_found
      end

      def serialize_group(g)
        {
          id:          g.id.to_s,
          name:        g.name,
          description: g.description,
          created_by:  g.created_by_id.to_s,
          created_at:  g.created_at.iso8601
        }
      end

      def serialize_user(u)
        { id: u.id.to_s, username: u.username, email: u.email, first_name: u.first_name, last_name: u.last_name }
      end

      def serialize_expense(e)
        {
          id:           e.id.to_s,
          description:  e.description,
          amount:       e.amount.to_f,
          category:     e.category,
          date:         e.date.iso8601,
          payer_id:     e.payer_id.to_s,
          payer_name:   e.payer.display_name,
          group_id:     e.group_id&.to_s,
          split_type:   e.split_type,
          participants: e.expense_participants.map { |p| p.user_id.to_s },
          splits:       e.expense_splits.each_with_object({}) { |s, h| h[s.user_id.to_s] = s.amount.to_f }
        }
      end
    end
  end
end
