class Investment < ApplicationRecord
  TYPES = %w[STOCK CRYPTO MUTUAL_FUND REAL_ESTATE OTHER].freeze

  belongs_to :user
  belongs_to :category, optional: true
  has_many :activity_logs, as: :loggable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  validates :name, :investment_type, :date, presence: true
  validates :amount_invested, :current_value, numericality: { greater_than_or_equal_to: 0 }
  validates :investment_type, inclusion: { in: TYPES }
end
