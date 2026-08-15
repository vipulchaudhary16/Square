class GroupInvite < ApplicationRecord
  belongs_to :group

  STATUSES = %w[pending accepted].freeze

  validates :token, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  before_validation :set_defaults, on: :create

  scope :pending_valid, -> { where(status: "pending").where("expires_at > ?", Time.current) }

  def self.accept!(token:, current_user:)
    invite = pending_valid.find_by(token: token)
    return nil unless invite

    user = User.find_by("lower(email) = ?", invite.email.downcase) || current_user

    transaction do
      GroupMembership.find_or_create_by!(group: invite.group, user: user)
      invite.update!(status: "accepted")
    end
    invite
  end

  private

  def set_defaults
    self.status ||= "pending"
  end
end
