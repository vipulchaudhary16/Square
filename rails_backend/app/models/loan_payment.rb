class LoanPayment < ApplicationRecord
  belongs_to :loan

  validates :loan_id, :amount, :paid_at, presence: true
  validates :amount, numericality: { greater_than: 0 }

  def api_json
    { id: id.to_s, loan_id: loan_id.to_s, amount: amount.to_f,
      paid_at: paid_at.iso8601, note: note, created_at: created_at.iso8601 }
  end
end
