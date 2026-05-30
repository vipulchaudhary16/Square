# Run with: rails db:seed
# Idempotent — safe to run multiple times.

# ── Feature Flag Registry ──────────────────────────────────────────────────────
[
  {
    key:             "groups_feature",
    description:     "Enable Groups & shared expenses",
    category:        "Social",
    user_toggleable: true,
    default_value:   true,
  },
  {
    key:             "investments_feature",
    description:     "Enable Investment tracking",
    category:        "Finance",
    user_toggleable: true,
    default_value:   true,
  },
  {
    key:             "loans_feature",
    description:     "Enable Loan tracking",
    category:        "Finance",
    user_toggleable: true,
    default_value:   true,
  },
  {
    key:             "budgets_feature",
    description:     "Enable Budget planning",
    category:        "Finance",
    user_toggleable: true,
    default_value:   false,
  },
].each do |attrs|
  FeatureFlagRegistry.find_or_create_by!(key: attrs[:key]) do |r|
    r.description     = attrs[:description]
    r.category        = attrs[:category]
    r.user_toggleable = attrs[:user_toggleable]
    r.default_value   = attrs[:default_value]
  end
end

puts "Seeded #{FeatureFlagRegistry.count} feature flag(s)."

# ── Dev user + sample data (development only) ─────────────────────────────────
if Rails.env.development?
  user = User.find_or_initialize_by(email: "dev@square.test")
  if user.new_record?
    user.assign_attributes(
      first_name: "Dev",
      last_name:  "User",
      password:   "password123",
    )
    user.save!
    CategorySeeder.seed(user)
    puts "Created dev user: dev@square.test / password123"
  else
    puts "Dev user already exists."
  end

  # Contacts
  alice = Contact.find_or_create_by!(owner_user_id: user.id, name: "Alice") do |c|
    c.phone = "9876543210"
  end
  bob = Contact.find_or_create_by!(owner_user_id: user.id, name: "Bob") do |c|
    c.phone = "9123456789"
  end

  loan_cat  = user.categories.find_by(name: "Personal Loan")
  gen_cat   = user.categories.find_by(name: "General")
  food_cat  = user.categories.find_by(name: "Food")
  stock_cat = user.categories.find_by(name: "Stocks")

  # Loans
  if Loan.where(lender_user_id: user.id).none?
    Loan.create!(
      lender_user_id: user.id,
      contact:        alice,
      amount:         5000,
      date:           30.days.ago,
      due_date:       30.days.from_now,
      status:         "PENDING",
      description:    "Birthday loan",
      category:       loan_cat,
    )
    Loan.create!(
      lender_user_id: user.id,
      contact:        bob,
      amount:         2500,
      date:           10.days.ago,
      status:         "PARTIAL",
      description:    "Dinner split",
      category:       gen_cat,
      interest_mode:  "penalty",
      interest_rate:  0.01,
      interest_period: "daily",
      interest_basis:  "principal",
      due_date:        5.days.ago,
    )
    puts "Created 2 sample loans."
  end

  # Expenses
  if user.expenses_paid.none?
    expense = Expense.create!(
      payer:       user,
      amount:      800,
      date:        5.days.ago,
      description: "Team lunch",
      category:    food_cat,
    )
    ExpenseSplit.create!(expense: expense, user: user, amount: 800)
    puts "Created 1 sample expense."
  end

  # Incomes
  if user.incomes.none?
    Income.create!(user: user, amount: 80_000, date: 1.month.ago, source: "Salary", description: "Monthly salary", category: gen_cat)
    puts "Created 1 sample income."
  end

  # Investments
  if user.investments.none?
    Investment.create!(user: user, name: "Nifty SIP", investment_type: "MUTUAL_FUND", amount_invested: 10_000, current_value: 10_500, date: 15.days.ago, description: "Monthly SIP", category: stock_cat)
    puts "Created 1 sample investment."
  end
end
