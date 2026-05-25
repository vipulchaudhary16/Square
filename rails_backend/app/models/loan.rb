class Loan < ApplicationRecord
  STATUSES              = %w[PENDING PARTIAL PAID].freeze
  CONFIRMATION_STATUSES = %w[pending confirmed disputed].freeze
  INTEREST_MODES        = %w[none from_start penalty].freeze
  INTEREST_PERIODS      = %w[daily monthly annual].freeze
  INTEREST_BASES        = %w[principal total].freeze

  belongs_to :lender,   class_name: "User", foreign_key: :lender_user_id
  belongs_to :borrower, class_name: "User", foreign_key: :borrower_user_id, optional: true
  belongs_to :contact
  belongs_to :category, optional: true
  has_many :activity_logs, as: :loggable, dependent: :destroy
  has_many :comments,      as: :commentable, dependent: :destroy
  has_many :loan_payments, dependent: :destroy
  has_many :loan_reminders, dependent: :destroy

  validates :lender_user_id, :contact_id, :amount, :date, :status, presence: true
  validates :status,              inclusion: { in: STATUSES }
  validates :confirmation_status, inclusion: { in: CONFIRMATION_STATUSES }
  validates :interest_mode,       inclusion: { in: INTEREST_MODES }, allow_nil: true
  validates :interest_period,     inclusion: { in: INTEREST_PERIODS }, allow_nil: true
  validates :interest_basis,      inclusion: { in: INTEREST_BASES }, allow_nil: true
  validates :amount,              numericality: { greater_than: 0 }
  validates :interest_rate,       numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :due_date,            presence: true, if: -> { interest_mode == "penalty" }
  validate :contact_belongs_to_lender

  scope :for_user, ->(user_id) {
    where("lender_user_id = ? OR borrower_user_id = ?", user_id, user_id)
  }

  def lender_for?(user_id)
    lender_user_id == user_id
  end

  private

  def contact_belongs_to_lender
    return unless contact && lender_user_id
    errors.add(:contact, "must belong to the lender") unless contact.owner_user_id == lender_user_id
  end
end
