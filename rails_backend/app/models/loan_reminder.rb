class LoanReminder < ApplicationRecord
  belongs_to :loan
  belongs_to :set_by_user, class_name: "User"

  validates :loan_id, :set_by_user_id, :remind_at, presence: true

  def api_json
    { id: id.to_s, loan_id: loan_id.to_s, remind_at: remind_at.iso8601,
      nudge_borrower: nudge_borrower, created_at: created_at.iso8601 }
  end
end
