class ActivityLog < ApplicationRecord
  belongs_to :loggable, polymorphic: true
  belongs_to :user
  validates :action, presence: true

  def self.record!(loggable:, user:, action:, details: "")
    create!(loggable: loggable, user: user, action: action, details: details)
  end

  def api_json(include_user: true)
    json = { id: id.to_s, action: action, details: details, created_at: created_at.iso8601 }
    json[:user_id] = user_id.to_s if include_user
    json
  end
end
