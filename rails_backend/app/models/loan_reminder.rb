class LoanReminder < ApplicationRecord
  belongs_to :loan
  belongs_to :set_by_user, class_name: "User"

  validates :loan_id, :set_by_user_id, :remind_at, presence: true
end
