class GroupInvite < ApplicationRecord
  belongs_to :group

  STATUSES = %w[pending accepted].freeze

  validates :token, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  before_validation :set_defaults, on: :create

  scope :pending_valid, -> { where(status: "pending").where("expires_at > ?", Time.current) }

  private

  def set_defaults
    self.status ||= "pending"
  end
end
