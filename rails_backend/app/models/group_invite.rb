class GroupInvite < ApplicationRecord
  belongs_to :group

  STATUSES = %w[pending accepted revoked].freeze

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

  # The invite is only ever redeemable by whoever holds this email address —
  # used by the web join page, which has no bearer token to fall back on.
  def invited_user
    User.find_by("lower(email) = ?", email.downcase)
  end

  def expired?
    status == "pending" && expires_at < Time.current
  end

  def revoke!
    update!(status: "revoked")
  end

  def accept_for_web!(password)
    user = invited_user
    return false unless user&.authenticate(password)

    transaction do
      GroupMembership.find_or_create_by!(group: group, user: user)
      update!(status: "accepted")
    end
    true
  end

  # "expired" isn't a stored status — a pending row just ages out — but the
  # UI (admin's invite list, the join page) needs to show it as its own state.
  def display_status
    expired? ? "expired" : status
  end

  def link
    "#{ENV.fetch('APP_URL', 'http://localhost:8080')}/invites/#{token}"
  end

  def api_json
    {
      id:         id.to_s,
      email:      email,
      status:     display_status,
      link:       link,
      created_at: created_at.iso8601,
      expires_at: expires_at.iso8601
    }
  end

  private

  def set_defaults
    self.status ||= "pending"
  end
end
