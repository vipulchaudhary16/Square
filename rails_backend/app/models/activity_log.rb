class ActivityLog < ApplicationRecord
  belongs_to :loggable, polymorphic: true
  belongs_to :user
  belongs_to :to_user, class_name: "User", optional: true
  validates :action, presence: true

  scope :settlements, -> { where(action: "SETTLE") }

  def self.record!(loggable:, user:, action:, details: "", to_user: nil, amount: nil)
    create!(loggable: loggable, user: user, action: action, details: details, to_user: to_user, amount: amount)
  end

  def api_json(include_user: true)
    json = { id: id.to_s, action: action, details: details, created_at: created_at.iso8601 }
    json[:user_id] = user_id.to_s if include_user
    json
  end

  def settlement_json
    {
      id:             id.to_s,
      type:           "settlement",
      amount:         amount.to_f,
      date:           created_at.iso8601,
      from_user_id:   user_id.to_s,
      from_user_name: user.display_name,
      to_user_id:     to_user_id.to_s,
      to_user_name:   to_user.display_name,
      group_id:       loggable_id.to_s
    }
  end
end
