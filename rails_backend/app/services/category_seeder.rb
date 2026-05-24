class CategorySeeder
  STANDARD = [
    { name: "Food",           applies_to: %w[expense income budget] },
    { name: "Transport",      applies_to: %w[expense income budget] },
    { name: "Utilities",      applies_to: %w[expense income budget] },
    { name: "Entertainment",  applies_to: %w[expense income budget] },
    { name: "Shopping",       applies_to: %w[expense income budget] },
    { name: "Health",         applies_to: %w[expense income budget] },
    { name: "Travel",         applies_to: %w[expense income budget] },
    { name: "General",        applies_to: %w[expense income budget investment loan] },
    { name: "Other",          applies_to: %w[expense income budget investment loan] },
    # Investment
    { name: "Stocks",         applies_to: %w[investment] },
    { name: "Crypto",         applies_to: %w[investment] },
    { name: "Mutual Funds",   applies_to: %w[investment] },
    { name: "Real Estate",    applies_to: %w[investment] },
    { name: "Gold",           applies_to: %w[investment] },
    { name: "Fixed Deposit",  applies_to: %w[investment] },
    # Loan
    { name: "Personal Loan",  applies_to: %w[loan] },
    { name: "Business Loan",  applies_to: %w[loan] },
    { name: "Home Loan",      applies_to: %w[loan] },
    { name: "Vehicle Loan",   applies_to: %w[loan] },
    { name: "Education Loan", applies_to: %w[loan] },
  ].freeze

  def self.seed(user)
    STANDARD.each do |attrs|
      user.categories.find_or_create_by!(name: attrs[:name]) do |cat|
        cat.applies_to  = attrs[:applies_to]
        cat.is_standard = true
      end
    end
  end
end
