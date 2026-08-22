class Group < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :group_invites, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :activity_logs, as: :loggable, dependent: :destroy

  validates :name, presence: true

  def self.create_with_owner!(name:, description:, user:)
    group = new(name: name, description: description || "", created_by: user)
    transaction do
      group.save!
      GroupMembership.create!(group: group, user: user)
    end
    group
  end

  def invite!(email)
    invite = group_invites.create!(email: email, token: SecureRandom.hex(32), expires_at: 48.hours.from_now)
    UserMailer.group_invite(email, self, invite.token).deliver_later
    invite
  end

  def add_member!(user)
    GroupMembership.find_or_create_by!(group: self, user: user)
  end

  class DebtExceededError < StandardError; end

  def settlements
    activity_logs.settlements
  end

  def debts
    DebtSettlementService.compute(
      expenses.includes(:expense_participants, :expense_splits),
      settlements.includes(:user, :to_user)
    )
  end

  def settle_debt!(from_user:, to_user:, amount:)
    amount = amount.to_f
    raise ArgumentError, "amount must be positive" unless amount > 0.01

    owed = debts.find { |d| d.from_id == from_user.id && d.to_id == to_user.id }&.amount || 0.0
    raise DebtExceededError, "amount exceeds what is owed" if amount > owed + 0.01

    ActivityLog.record!(
      loggable: self, user: from_user, action: "SETTLE", to_user: to_user, amount: amount,
      details: "#{from_user.display_name} paid #{to_user.display_name} #{amount}"
    )
  end

  def api_json
    { id: id.to_s, name: name, description: description,
      created_by: created_by_id.to_s, created_at: created_at.iso8601, members: members.map(&:member_json) }
  end
end
