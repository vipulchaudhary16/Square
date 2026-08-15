class Loan < ApplicationRecord
  include Trackable

  class AlreadySettledError < StandardError; end

  STATUSES              = %w[PENDING PARTIAL PAID].freeze
  CONFIRMATION_STATUSES = %w[pending confirmed disputed].freeze
  INTEREST_MODES        = %w[none from_start penalty].freeze
  INTEREST_PERIODS      = %w[daily monthly annual].freeze
  INTEREST_BASES        = %w[principal total].freeze
  TRACKED_FIELDS         = %i[amount date due_date status description interest_mode interest_rate].freeze

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

  def self.create_for_lender!(lender:, contact_id:, attrs:)
    raise ArgumentError, "contact_id is required" if contact_id.blank?
    contact = lender.owned_contacts.find(contact_id)
    create!(attrs.merge(
      lender_user_id:   lender.id,
      contact_id:       contact.id,
      borrower_user_id: contact.linked_user_id
    ))
  end

  def self.net_balance_for(loans, user_id)
    lent     = loans.select { |l| l.lender_for?(user_id) }.sum(&:amount).to_f
    borrowed = loans.reject { |l| l.lender_for?(user_id) }.sum(&:amount).to_f
    diff     = lent - borrowed
    { direction: diff >= 0 ? "owed_to_you" : "you_owe", amount: diff.abs }
  end

  def lender_for?(user_id)
    lender_user_id == user_id
  end

  def apply_update!(attrs, current_user:)
    changes = track_changes(attrs, TRACKED_FIELDS)
    if update(attrs)
      ActivityLog.record!(loggable: self, user: current_user, action: "UPDATE", details: changes.join(", ")) if changes.any?
      true
    else
      false
    end
  end

  def update_confirmation(status)
    raise ArgumentError, "Invalid confirmation_status" unless CONFIRMATION_STATUSES.include?(status)
    update(confirmation_status: status, confirmed_at: status == "confirmed" ? Time.current : nil)
  end

  def record_payment!(amount:, paid_at:, note: nil, add_interest_to_income: false)
    raise AlreadySettledError, "Loan is already settled" if status == "PAID"

    payment = nil
    transaction do
      payment = loan_payments.create!(amount: amount, paid_at: paid_at, note: note)
      update_status_from_payments!
      create_interest_income! if add_interest_to_income
    end
    payment
  end

  def schedule_reminder!(set_by:, remind_at:, nudge_borrower: false, via_push: true, via_sms: false, via_email: true)
    loan_reminders.create!(
      set_by_user_id: set_by.id,
      remind_at:      remind_at,
      nudge_borrower: nudge_borrower,
      via_push:       via_push,
      via_sms:        via_sms,
      via_email:      via_email
    )
  end

  def api_json(calc: nil, current_user: nil)
    calc ||= InterestCalculatorService.new(self).call
    {
      id:                  id.to_s,
      lender_user_id:      lender_user_id.to_s,
      borrower_user_id:    borrower_user_id&.to_s,
      contact_id:          contact_id.to_s,
      contact_name:        contact&.name || "",
      direction:           current_user ? (lender_for?(current_user.id) ? "lent" : "borrowed") : nil,
      amount:              amount.to_f,
      outstanding:         calc[:outstanding],
      accrued_interest:    calc[:accrued_interest],
      total_due:           calc[:total_due],
      date:                date.iso8601,
      due_date:            due_date&.iso8601,
      status:              status,
      confirmation_status: confirmation_status,
      interest_mode:       interest_mode,
      interest_rate:       interest_rate&.to_f,
      interest_period:     interest_period,
      interest_basis:      interest_basis,
      description:         description,
      category_id:         category_id&.to_s,
      category_name:       category&.name || "",
      created_at:          created_at.iso8601
    }
  end

  def brief_json(current_user)
    {
      id:            id.to_s,
      direction:     lender_for?(current_user.id) ? "lent" : "borrowed",
      amount:        amount.to_f,
      status:        status,
      date:          date.iso8601,
      due_date:      due_date&.iso8601,
      description:   description,
      category_name: category&.name || "",
      interest_mode: interest_mode
    }
  end

  def payment_summary_json(calc)
    { id: id.to_s, status: status, outstanding: calc[:outstanding],
      accrued_interest: calc[:accrued_interest], total_due: calc[:total_due] }
  end

  private

  def update_status_from_payments!
    total_paid = loan_payments.sum(:amount)
    if total_paid >= amount
      update!(status: "PAID")
    elsif total_paid > 0
      update!(status: "PARTIAL")
    end
  end

  def create_interest_income!
    calc = InterestCalculatorService.new(self).call
    return unless calc[:accrued_interest] > 0

    category = lender.categories.find_or_initialize_by(name: "Interest Income")
    category.applies_to = ["income"]
    category.save! if category.new_record?

    income = lender.incomes.find_or_initialize_by(source: "Interest on loan: #{contact.name}")
    income.assign_attributes(amount: calc[:accrued_interest], date: Date.today, category_id: category.id)
    income.save!
  end

  def contact_belongs_to_lender
    return unless contact && lender_user_id
    errors.add(:contact, "must belong to the lender") unless contact.owner_user_id == lender_user_id
  end
end
