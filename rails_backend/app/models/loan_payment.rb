class LoanPayment < ApplicationRecord
  belongs_to :loan

  validates :loan_id, :amount, :paid_at, presence: true
  validates :amount, numericality: { greater_than: 0 }
end
