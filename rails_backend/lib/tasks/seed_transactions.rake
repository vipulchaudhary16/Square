# lib/tasks/seed_transactions.rake
#
# Seed random transactions for a user across all financial tables.
#
# USAGE
# ─────
#   rails seed:transactions USER_ID=<id>
#
# OPTIONAL ENV VARS
# ─────────────────
#   COUNT=<n>          Total records to create (split evenly across enabled tables). Default: 400
#   FROM=today-90      Earliest date. Use "today", "today-<days>", or "YYYY-MM-DD". Default: today-365
#   TO=today           Latest  date. Same format. Default: today
#   TABLES=expense,income,investment,loan
#                      Comma-separated list of tables to seed. Default: all four
#
# EXAMPLES
# ────────
#   rails seed:transactions USER_ID=1
#   rails seed:transactions USER_ID=1 COUNT=200 FROM=today-30 TO=today
#   rails seed:transactions USER_ID=1 FROM=2025-01-01 TO=today-7
#   rails seed:transactions USER_ID=1 TABLES=expense,loan COUNT=50

namespace :seed do
  desc <<~DESC
    Seed random transactions (expenses, incomes, investments, loans) for a user.

    Required:
      USER_ID=<id>

    Optional:
      COUNT=400          Total records (split evenly across enabled tables).
      FROM=today-365     Start date. Formats: "today", "today-<n>", "YYYY-MM-DD".
      TO=today           End date.   Same formats.
      TABLES=expense,income,investment,loan
  DESC

  task transactions: :environment do
    # ── Input parsing ──────────────────────────────────────────────────────

    user_id = ENV["USER_ID"].presence&.to_i or abort "ERROR: USER_ID is required.\n  Usage: rails seed:transactions USER_ID=<id>"
    user    = User.find_by(id: user_id)     or abort "ERROR: User #{user_id} not found."

    # Parse flexible date format: "today", "today-N", or "YYYY-MM-DD"
    parse_date = lambda do |str, default_offset_days|
      str = str.presence || "today-#{default_offset_days}"
      case str
      when /\Atoday\z/i
        Date.current
      when /\Atoday-(\d+)\z/i
        Date.current - Regexp.last_match(1).to_i.days
      when /\A\d{4}-\d{2}-\d{2}\z/
        Date.parse(str)
      else
        abort "ERROR: Invalid date format '#{str}'. Use 'today', 'today-<n>', or 'YYYY-MM-DD'."
      end
    end

    from_date = parse_date.(ENV["FROM"], 365)
    to_date   = parse_date.(ENV["TO"],   0)

    abort "ERROR: FROM date (#{from_date}) must be before or equal to TO date (#{to_date})." if from_date > to_date

    valid_tables  = %w[expense income investment loan]
    tables_input  = ENV["TABLES"].presence&.split(",")&.map(&:strip)&.map(&:downcase) || valid_tables
    invalid       = tables_input - valid_tables
    abort "ERROR: Unknown tables: #{invalid.join(', ')}. Valid: #{valid_tables.join(', ')}." if invalid.any?

    total_count  = (ENV["COUNT"].presence || "400").to_i
    abort "ERROR: COUNT must be a positive integer." unless total_count > 0

    per_table = (total_count.to_f / tables_input.size).ceil

    puts <<~BANNER
      ╔══════════════════════════════════════════════════════════════╗
      ║              Square — Transaction Seeder                     ║
      ╠══════════════════════════════════════════════════════════════╣
      ║  User    : #{user.email.ljust(48)}║
      ║  Period  : #{from_date} → #{to_date}#{" " * (35 - (from_date.to_s + to_date.to_s).length)}║
      ║  Tables  : #{tables_input.join(", ").ljust(48)}║
      ║  Per tbl : #{per_table.to_s.ljust(48)}║
      ╚══════════════════════════════════════════════════════════════╝
    BANNER

    # ── Date helper ────────────────────────────────────────────────────────
    range_seconds = ((to_date.end_of_day - from_date.beginning_of_day)).to_i
    rand_date     = -> { from_date.beginning_of_day + rand(0..range_seconds).seconds }

    # ── Category helper ────────────────────────────────────────────────────
    find_or_create_cat = lambda do |name, types|
      Category.find_or_create_by!(name: name, user_id: user_id) do |c|
        c.applies_to  = types
        c.is_standard = Category::STANDARD_NAMES.include?(name)
      end
    end

    # ── Seed Expenses ──────────────────────────────────────────────────────
    if tables_input.include?("expense")
      expense_categories = {
        "Food"          => find_or_create_cat.("Food",          %w[expense budget]),
        "Transport"     => find_or_create_cat.("Transport",     %w[expense budget]),
        "Utilities"     => find_or_create_cat.("Utilities",     %w[expense budget]),
        "Entertainment" => find_or_create_cat.("Entertainment", %w[expense budget]),
        "Shopping"      => find_or_create_cat.("Shopping",      %w[expense budget]),
        "Health"        => find_or_create_cat.("Health",        %w[expense budget]),
        "Travel"        => find_or_create_cat.("Travel",        %w[expense budget]),
        "General"       => find_or_create_cat.("General",       %w[expense budget]),
        "Other"         => find_or_create_cat.("Other",         %w[expense budget]),
      }

      expense_templates = [
        # [description, category_name, amount_range]
        ["Grocery shopping",       "Food",          200..3_000 ],
        ["Coffee",                 "Food",          50..300    ],
        ["Restaurant dinner",      "Food",          300..2_500 ],
        ["Lunch",                  "Food",          100..500   ],
        ["Zomato order",           "Food",          150..600   ],
        ["Swiggy order",           "Food",          150..600   ],
        ["Blinkit order",          "Food",          100..800   ],
        ["Zepto order",            "Food",          100..500   ],
        ["Electricity bill",       "Utilities",     800..3_000 ],
        ["Water bill",             "Utilities",     100..500   ],
        ["Internet bill",          "Utilities",     500..1_500 ],
        ["Mobile recharge",        "Utilities",     100..600   ],
        ["Gas cylinder",           "Utilities",     800..1_200 ],
        ["Uber ride",              "Transport",     80..600    ],
        ["Ola cab",                "Transport",     80..600    ],
        ["Rapido bike",            "Transport",     30..200    ],
        ["Metro card recharge",    "Transport",     200..500   ],
        ["Petrol",                 "Transport",     500..2_000 ],
        ["Vehicle maintenance",    "Transport",     500..5_000 ],
        ["Movie tickets",          "Entertainment", 200..800   ],
        ["Netflix subscription",   "Entertainment", 149..649   ],
        ["Spotify subscription",   "Entertainment", 119..299   ],
        ["Concert tickets",        "Entertainment", 500..5_000 ],
        ["Amazon order",           "Shopping",      300..5_000 ],
        ["Flipkart order",         "Shopping",      200..4_000 ],
        ["Clothing purchase",      "Shopping",      500..5_000 ],
        ["Electronics purchase",   "Shopping",      1_000..50_000],
        ["Gym membership",         "Health",        500..3_000 ],
        ["Doctor consultation",    "Health",        300..1_500 ],
        ["Medicines",              "Health",        100..800   ],
        ["Lab tests",              "Health",        200..2_000 ],
        ["Dental treatment",       "Health",        500..5_000 ],
        ["Flight ticket",          "Travel",        2_000..15_000],
        ["Hotel stay",             "Travel",        1_500..8_000 ],
        ["Train ticket",           "Travel",        200..2_000  ],
        ["Travel insurance",       "Travel",        300..1_500  ],
        ["Rent",                   "General",       5_000..50_000],
        ["Home maintenance",       "General",       500..10_000 ],
        ["Charity / donation",     "Other",         100..5_000  ],
        ["Miscellaneous",          "Other",         100..2_000  ],
      ]

      expenses = Array.new(per_table) do
        desc, cat_name, range = expense_templates.sample
        d = rand_date.()
        {
          description: desc,
          amount:      rand(range),
          date:        d,
          payer_id:    user_id,
          group_id:    nil,
          split_type:  nil,
          category_id: expense_categories[cat_name].id,
          created_at:  d,
          updated_at:  d,
        }
      end

      Expense.insert_all!(expenses)
      puts "  ✓ #{per_table} expenses inserted"
    end

    # ── Seed Incomes ───────────────────────────────────────────────────────
    if tables_input.include?("income")
      income_categories = {
        "Salary"        => find_or_create_cat.("Salary",        %w[income]),
        "Freelance"     => find_or_create_cat.("Freelance",     %w[income]),
        "Rental"        => find_or_create_cat.("Rental",        %w[income]),
        "Dividend"      => find_or_create_cat.("Dividend",      %w[income]),
        "Bonus"         => find_or_create_cat.("Bonus",         %w[income]),
        "Interest"      => find_or_create_cat.("Interest",      %w[income]),
        "Side Business" => find_or_create_cat.("Side Business", %w[income]),
        "Other"         => find_or_create_cat.("Other",         %w[income expense budget]),
      }

      income_templates = [
        # [source, description, category_name, amount_range]
        ["Salary",        "Monthly salary deposit",       "Salary",        30_000..150_000],
        ["Freelance",     "Freelance project payment",    "Freelance",      5_000..50_000 ],
        ["Consulting",    "Consulting fee received",      "Freelance",     10_000..80_000 ],
        ["Rental Income", "Property rental income",       "Rental",         8_000..40_000 ],
        ["Dividend",      "Stock dividend payout",        "Dividend",         500..10_000 ],
        ["Bonus",         "Performance bonus",            "Bonus",         10_000..100_000],
        ["Interest",      "FD / savings interest",        "Interest",         200..5_000  ],
        ["Side Project",  "Side business revenue",        "Side Business",  2_000..30_000 ],
        ["Referral",      "Referral bonus received",      "Bonus",            500..5_000  ],
        ["Cashback",      "Credit card cashback",         "Other",            100..2_000  ],
        ["Tuition",       "Private tuition income",       "Side Business",  1_000..15_000 ],
        ["Commission",    "Sales commission",             "Salary",         2_000..20_000 ],
      ]

      incomes = Array.new(per_table) do
        source, desc, cat_name, range = income_templates.sample
        d = rand_date.()
        {
          user_id:     user_id,
          source:      source,
          amount:      rand(range),
          date:        d,
          description: desc,
          category_id: income_categories[cat_name].id,
          created_at:  d,
          updated_at:  d,
        }
      end

      Income.insert_all!(incomes)
      puts "  ✓ #{per_table} incomes inserted"
    end

    # ── Seed Investments ───────────────────────────────────────────────────
    if tables_input.include?("investment")
      inv_cat_map = {
        "STOCK"       => find_or_create_cat.("Stocks",       %w[investment]),
        "CRYPTO"      => find_or_create_cat.("Crypto",       %w[investment]),
        "MUTUAL_FUND" => find_or_create_cat.("Mutual Funds", %w[investment]),
        "REAL_ESTATE" => find_or_create_cat.("Real Estate",  %w[investment]),
        "OTHER"       => find_or_create_cat.("Gold",         %w[investment]),
      }

      inv_names = {
        "STOCK" => [
          "Reliance Industries", "HDFC Bank", "Infosys", "TCS", "ICICI Bank",
          "Bajaj Finance", "Wipro", "HUL", "Asian Paints", "SBI",
          "Kotak Mahindra Bank", "Maruti Suzuki", "Larsen & Toubro", "Axis Bank",
          "Titan Company", "Bharti Airtel", "ITC", "Power Grid Corp", "NTPC",
        ],
        "CRYPTO" => [
          "Bitcoin", "Ethereum", "Solana", "BNB", "Cardano",
          "Polkadot", "Avalanche", "Polygon", "Chainlink", "XRP",
          "Dogecoin", "Shiba Inu", "Uniswap", "Litecoin", "Ripple",
        ],
        "MUTUAL_FUND" => [
          "SBI Bluechip Fund", "Mirae Asset Large Cap", "Axis Long Term Equity",
          "HDFC Mid-Cap Opportunities", "Parag Parikh Flexi Cap",
          "Kotak Emerging Equity", "DSP Small Cap Fund", "Nippon India Growth",
          "ICICI Prudential Balanced", "Franklin India Prima Fund",
          "Motilal Oswal Nasdaq", "Aditya Birla Sun Life",
        ],
        "REAL_ESTATE" => [
          "Residential Plot - Whitefield", "Commercial Space - Koramangala",
          "Apartment - Pune", "Land Parcel - Hyderabad", "Shop - Delhi NCR",
          "Villa - Goa", "Office Floor - Mumbai", "Warehouse - Chennai",
        ],
        "OTHER" => [
          "Gold Sovereign Bond", "Physical Gold", "Silver ETF",
          "Gold ETF", "Digital Gold", "Fixed Deposit - SBI",
          "Fixed Deposit - HDFC", "NSC", "PPF", "NPS",
        ],
      }

      investments = Array.new(per_table) do
        inv_type = Investment::TYPES.sample
        invested = rand(1_000..500_000)
        current  = (invested * (rand(60..180) / 100.0)).round(2)
        d        = rand_date.()
        {
          user_id:         user_id,
          name:            inv_names[inv_type].sample,
          investment_type: inv_type,
          amount_invested: invested,
          current_value:   current,
          date:            d,
          description:     "#{inv_type.tr('_', ' ').downcase.capitalize} investment",
          category_id:     inv_cat_map[inv_type].id,
          created_at:      d,
          updated_at:      d,
        }
      end

      Investment.insert_all!(investments)
      puts "  ✓ #{per_table} investments inserted"
    end

    # ── Seed Loans ─────────────────────────────────────────────────────────
    if tables_input.include?("loan")
      loan_cat_map = {
        "LENT"     => find_or_create_cat.("Money Lent",     %w[loan]),
        "BORROWED" => find_or_create_cat.("Money Borrowed", %w[loan]),
      }

      first_names = %w[
        Rahul Priya Amit Sunita Vijay Neha Ravi Pooja Sanjay Anjali
        Deepak Meera Rohan Kavya Arjun Divya Karan Shruti Nikhil Ananya
        Aakash Sneha Gaurav Isha Manish Preeti Suresh Rekha Abhishek Pallavi
      ]
      last_names = %w[
        Sharma Patel Gupta Singh Verma Mehta Joshi Nair Kumar Reddy
        Shah Rao Agarwal Bose Iyer Pillai Chopra Malhotra Banerjee Das
        Srivastava Pandey Chaudhary Saxena Kapoor Khanna Dubey Tripathi
      ]

      loans = Array.new(per_table) do
        name  = "#{first_names.sample} #{last_names.sample}"
        ltype = Loan::TYPES.sample
        d     = rand_date.()
        {
          user_id:           user_id,
          counterparty_name: name,
          loan_type:         ltype,
          amount:            rand(1_000..500_000),
          date:              d,
          due_date:          d + rand(30..730).days,
          status:            Loan::STATUSES.sample,
          description:       ltype == "LENT" ? "Lent to #{name.split.first}" : "Borrowed from #{name.split.first}",
          category_id:       loan_cat_map[ltype].id,
          created_at:        d,
          updated_at:        d,
        }
      end

      Loan.insert_all!(loans)
      puts "  ✓ #{per_table} loans inserted"
    end

    total_inserted = tables_input.size * per_table
    puts "\n✅ Done — #{total_inserted} records seeded for #{user.email} between #{from_date} and #{to_date}."
  end
end
