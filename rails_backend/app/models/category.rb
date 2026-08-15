class Category < ApplicationRecord
  class ProtectedError < StandardError; end
  class MissingFallbackError < StandardError; end

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

  def destroy_with_reassignment!(fallback_name: "Other")
    raise ProtectedError, "Standard categories cannot be deleted" if is_standard

    other = user.categories.find_by(name: fallback_name)
    raise MissingFallbackError, "Cannot delete category: fallback '#{fallback_name}' category is missing" unless other

    ActiveRecord::Base.transaction do
      Expense.where(payer_id: user_id, category_id: id).update_all(category_id: other.id)
      Income.where(user_id: user_id, category_id: id).update_all(category_id: other.id)
      Budget.where(user_id: user_id, category_id: id).update_all(category_id: other.id)
      destroy!
    end
  end

  def api_json
    { id: id.to_s, name: name, applies_to: applies_to, is_standard: is_standard }
  end

  private

  def applies_to_must_be_valid
    valid_types = %w[expense income budget investment loan]
    unless applies_to.is_a?(Array) && applies_to.any? && applies_to.all? { |t| valid_types.include?(t) }
      errors.add(:applies_to, "must include at least one of: expense, income, budget, investment, loan")
    end
  end
end
