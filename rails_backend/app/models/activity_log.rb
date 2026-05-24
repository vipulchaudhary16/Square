class ActivityLog < ApplicationRecord
  belongs_to :loggable, polymorphic: true
  belongs_to :user
  validates :action, presence: true
end
