class Group < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :group_invites, dependent: :destroy
  has_many :expenses, dependent: :destroy

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

  def settle_debt!(from_user:, to_user:, amount:)
    expense = Expense.new(
      description: "Settlement",
      amount:      amount,
      category:    "Settlement",
      date:        Time.current,
      payer_id:    from_user.id,
      group_id:    id,
      split_type:  "EXACT"
    )
    transaction do
      expense.save!
      ExpenseParticipant.create!(expense: expense, user: to_user)
      ExpenseSplit.create!(expense: expense, user: to_user, amount: amount)
      ActivityLog.record!(
        loggable: expense, user: from_user, action: "SETTLE",
        details: "#{from_user.display_name} settled #{amount} with #{to_user.display_name}"
      )
    end
    expense
  end

  def api_json
    { id: id.to_s, name: name, description: description,
      created_by: created_by_id.to_s, created_at: created_at.iso8601 }
  end
end
