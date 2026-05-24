class AddInvestmentLoanCategoriesToExistingUsers < ActiveRecord::Migration[7.2]
  def up
    # Expand General and Other to cover investment and loan
    Category.where(is_standard: true, name: %w[General Other]).find_each do |cat|
      cat.update!(applies_to: (cat.applies_to | %w[investment loan]))
    end

    # Seed new investment/loan categories for all existing users
    User.find_each { |user| CategorySeeder.seed(user) }
  end

  def down
    Category.where(is_standard: true, name: %w[General Other]).find_each do |cat|
      cat.update!(applies_to: cat.applies_to - %w[investment loan])
    end

    investment_loan_names = %w[Stocks Crypto Gold] + ["Mutual Funds", "Real Estate", "Fixed Deposit",
                              "Personal Loan", "Business Loan", "Home Loan", "Vehicle Loan", "Education Loan"]
    Category.where(is_standard: true, name: investment_loan_names).delete_all
  end
end
