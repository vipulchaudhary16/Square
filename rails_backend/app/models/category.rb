class Category < ApplicationRecord
  STANDARD_NAMES = (
    %w[Food Transport Utilities Entertainment Shopping Health Travel General Other
       Stocks Crypto Gold] +
    ["Mutual Funds", "Real Estate", "Fixed Deposit",
     "Personal Loan", "Business Loan", "Home Loan", "Vehicle Loan", "Education Loan"]
  ).freeze

  belongs_to :user

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :applies_to, presence: true
  validate :applies_to_must_be_valid

  private

  def applies_to_must_be_valid
    valid_types = %w[expense income budget investment loan]
    unless applies_to.is_a?(Array) && applies_to.any? && applies_to.all? { |t| valid_types.include?(t) }
      errors.add(:applies_to, "must include at least one of: expense, income, budget, investment, loan")
    end
  end
end
