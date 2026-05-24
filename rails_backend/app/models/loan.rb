class Loan < ApplicationRecord
  TYPES    = %w[LENT BORROWED].freeze
  STATUSES = %w[PENDING PAID].freeze

  belongs_to :user
  belongs_to :category, optional: true
  has_many :activity_logs, as: :loggable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  validates :counterparty_name, :loan_type, :amount, :date, :status, presence: true
  validates :loan_type, inclusion: { in: TYPES }
  validates :status,    inclusion: { in: STATUSES }
  validates :amount,    numericality: { greater_than: 0 }
end
