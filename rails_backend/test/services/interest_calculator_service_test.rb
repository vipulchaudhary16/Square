require "test_helper"

class InterestCalculatorServiceTest < ActiveSupport::TestCase
  # ── Helpers ─────────────────────────────────────────────────────────────────

  def build_loan(overrides = {})
    lender  = create(:user)
    contact = create(:contact, owner: lender)
    create(:loan, {
      lender: lender, contact: contact,
      amount: 1_000, status: "PENDING",
      date: Date.today, interest_mode: "none"
    }.merge(overrides))
  end

  def call(loan)
    InterestCalculatorService.new(loan).call
  end

  # ── No interest ──────────────────────────────────────────────────────────────

  test "none: outstanding equals principal, zero interest, empty timeline" do
    loan   = build_loan(amount: 5_000, interest_mode: "none")
    result = call(loan)

    assert_equal 5_000.0, result[:outstanding]
    assert_equal 0.0,     result[:accrued_interest]
    assert_equal 5_000.0, result[:total_due]
    assert_empty          result[:interest_timeline]
  end

  test "none: payment reduces outstanding" do
    loan = build_loan(amount: 5_000, interest_mode: "none")
    create(:loan_payment, loan: loan, amount: 1_500)

    assert_equal 3_500.0, call(loan)[:outstanding]
  end

  test "none: outstanding is clamped to zero when overpaid" do
    loan = build_loan(amount: 1_000, interest_mode: "none")
    create(:loan_payment, loan: loan, amount: 1_200)

    assert_equal 0.0, call(loan)[:outstanding]
  end

  # ── Daily – simple ───────────────────────────────────────────────────────────

  test "daily simple: interest = principal × (rate/100) × days" do
    travel_to Date.new(2026, 6, 10) do
      loan = build_loan(
        amount: 900, date: Date.new(2026, 6, 1),
        interest_mode: "from_start",
        interest_rate: 3, interest_period: "daily", interest_basis: "principal"
      )
      result = call(loan)

      # 9 days elapsed (Jun 2 → Jun 10)
      assert_in_delta 900 * 0.03 * 9, result[:accrued_interest], 0.01
      assert_equal 9, result[:interest_timeline].length
    end
  end

  test "daily simple: each timeline entry has date, daily_interest, cumulative" do
    travel_to Date.new(2026, 6, 4) do
      loan = build_loan(
        amount: 1_000, date: Date.new(2026, 6, 1),
        interest_mode: "from_start",
        interest_rate: 1, interest_period: "daily", interest_basis: "principal"
      )
      entries = call(loan)[:interest_timeline]

      assert_equal 3, entries.length
      assert_equal "2026-06-02", entries.first[:date]
      assert_in_delta 10.0, entries.first[:daily_interest], 0.01
      assert_in_delta 30.0, entries.last[:cumulative], 0.01
    end
  end

  test "daily simple: cumulative of last entry equals accrued_interest" do
    travel_to Date.new(2026, 6, 6) do
      loan = build_loan(
        amount: 1_000, date: Date.new(2026, 6, 1),
        interest_mode: "from_start",
        interest_rate: 2, interest_period: "daily", interest_basis: "principal"
      )
      result  = call(loan)
      assert_in_delta result[:accrued_interest], result[:interest_timeline].last[:cumulative], 0.01
    end
  end

  # ── Daily – compound ─────────────────────────────────────────────────────────

  test "daily compound: uses (1 + r)^n - 1 formula" do
    travel_to Date.new(2026, 6, 11) do
      loan = build_loan(
        amount: 1_000, date: Date.new(2026, 6, 1),
        interest_mode: "from_start",
        interest_rate: 1, interest_period: "daily", interest_basis: "total"
      )
      result   = call(loan)
      expected = 1_000 * ((1.01**10) - 1)

      assert_in_delta expected, result[:accrued_interest], 0.01
    end
  end

  test "daily compound: accrued_interest exceeds simple for same inputs" do
    travel_to Date.new(2026, 6, 11) do
      simple   = build_loan(
        amount: 1_000, date: Date.new(2026, 6, 1),
        interest_mode: "from_start",
        interest_rate: 1, interest_period: "daily", interest_basis: "principal"
      )
      compound = build_loan(
        amount: 1_000, date: Date.new(2026, 6, 1),
        interest_mode: "from_start",
        interest_rate: 1, interest_period: "daily", interest_basis: "total"
      )

      assert call(compound)[:accrued_interest] > call(simple)[:accrued_interest]
    end
  end

  # ── Monthly – flat rate per calendar month ───────────────────────────────────

  test "monthly: each complete month accrues the same interest regardless of days in month" do
    # date=Feb 1, start=Feb 2. Travel to Jun 2 → 4 complete periods: Feb2→Mar2, Mar2→Apr2, Apr2→May2, May2→Jun2
    travel_to Date.new(2026, 6, 2) do
      loan = build_loan(
        amount: 900, date: Date.new(2026, 2, 1),
        interest_mode: "from_start",
        interest_rate: 3, interest_period: "monthly", interest_basis: "principal"
      )
      entries = call(loan)[:interest_timeline]

      amounts = entries.map { |e| e[:period_interest] }
      assert_equal 4, amounts.length, "Expected 4 monthly entries"
      assert amounts.uniq.length == 1, "Expected equal interest per month, got: #{amounts.inspect}"
      assert_in_delta 27.0, amounts.first, 0.01
    end
  end

  test "monthly: March (31 days) and April (30 days) produce equal interest" do
    # date=Mar 1, start=Mar 2. Travel to May 2 → 2 complete periods: Mar2→Apr2, Apr2→May2
    travel_to Date.new(2026, 5, 2) do
      loan = build_loan(
        amount: 900, date: Date.new(2026, 3, 1),
        interest_mode: "from_start",
        interest_rate: 3, interest_period: "monthly", interest_basis: "principal"
      )
      entries = call(loan)[:interest_timeline]
      march = entries.find { |e| e[:date].include?("March") }
      april = entries.find { |e| e[:date].include?("April") }

      assert_not_nil march
      assert_not_nil april
      assert_in_delta march[:period_interest], april[:period_interest], 0.001
    end
  end

  test "monthly: partial current month is prorated by days elapsed / days in month" do
    # date=May 1, start=May 2. Travel to May 17 → 15 days elapsed in May (May2→May17). period_length=31
    travel_to Date.new(2026, 5, 17) do
      loan = build_loan(
        amount: 900, date: Date.new(2026, 5, 1),
        interest_mode: "from_start",
        interest_rate: 3, interest_period: "monthly", interest_basis: "principal"
      )
      entries   = call(loan)[:interest_timeline]
      may_entry = entries.find { |e| e[:date].include?("May") }

      expected = 900 * 0.03 * (15.0 / 31)
      assert_in_delta expected, may_entry[:period_interest], 0.01
    end
  end

  test "monthly: timeline entries use month name labels" do
    travel_to Date.new(2026, 4, 1) do
      loan = build_loan(
        amount: 1_000, date: Date.new(2026, 2, 1),
        interest_mode: "from_start",
        interest_rate: 2, interest_period: "monthly", interest_basis: "principal"
      )
      labels = call(loan)[:interest_timeline].map { |e| e[:date] }

      assert_includes labels, "February 2026"
      assert_includes labels, "March 2026"
    end
  end

  test "monthly: cumulative of last entry equals accrued_interest" do
    travel_to Date.new(2026, 5, 15) do
      loan = build_loan(
        amount: 1_000, date: Date.new(2026, 3, 1),
        interest_mode: "from_start",
        interest_rate: 2, interest_period: "monthly", interest_basis: "principal"
      )
      result = call(loan)
      assert_in_delta result[:accrued_interest], result[:interest_timeline].last[:cumulative], 0.01
    end
  end

  # ── Annual ───────────────────────────────────────────────────────────────────

  test "annual: each complete year accrues the same interest" do
    # date=Jan 1 2026, start=Jan 2 2026. Travel to Jan 2 2028 → 2 complete periods
    travel_to Date.new(2028, 1, 2) do
      loan = build_loan(
        amount: 10_000, date: Date.new(2026, 1, 1),
        interest_mode: "from_start",
        interest_rate: 12, interest_period: "annual", interest_basis: "principal"
      )
      entries = call(loan)[:interest_timeline]
      amounts = entries.map { |e| e[:period_interest] }

      assert_equal 2, amounts.length
      assert_in_delta amounts.first, amounts.last, 0.01
      assert_in_delta 1_200.0, amounts.first, 0.01
    end
  end

  test "annual: timeline entries use year labels" do
    travel_to Date.new(2028, 1, 2) do
      loan = build_loan(
        amount: 1_000, date: Date.new(2026, 1, 1),
        interest_mode: "from_start",
        interest_rate: 10, interest_period: "annual", interest_basis: "principal"
      )
      labels = call(loan)[:interest_timeline].map { |e| e[:date] }

      assert_includes labels, "2026"
      assert_includes labels, "2027"
    end
  end

  # ── Penalty mode ─────────────────────────────────────────────────────────────

  test "penalty: zero interest when loan is not yet overdue" do
    travel_to Date.new(2026, 6, 1) do
      loan = build_loan(
        amount: 5_000, date: Date.new(2026, 5, 1),
        interest_mode: "penalty", due_date: Date.new(2026, 6, 10),
        interest_rate: 2, interest_period: "daily", interest_basis: "principal"
      )
      result = call(loan)

      assert_equal 0.0, result[:accrued_interest]
      assert_empty result[:interest_timeline]
    end
  end

  test "penalty: interest accrues only after due_date" do
    travel_to Date.new(2026, 6, 15) do
      loan = build_loan(
        amount: 5_000, date: Date.new(2026, 5, 1),
        interest_mode: "penalty", due_date: Date.new(2026, 6, 10),
        interest_rate: 2, interest_period: "daily", interest_basis: "principal"
      )
      result = call(loan)

      # 5 days overdue (Jun 11 → Jun 15)
      assert_in_delta 5_000 * 0.02 * 5, result[:accrued_interest], 0.01
      assert_equal 5, result[:interest_timeline].length
    end
  end

  test "penalty monthly: equal monthly interest after due_date" do
    # due_date=Jun 1, start=Jun 2. Travel to Sep 2 → 3 complete periods: Jun2→Jul2, Jul2→Aug2, Aug2→Sep2
    travel_to Date.new(2026, 9, 2) do
      loan = build_loan(
        amount: 900, date: Date.new(2026, 3, 1),
        interest_mode: "penalty", due_date: Date.new(2026, 6, 1),
        interest_rate: 3, interest_period: "monthly", interest_basis: "principal"
      )
      entries = call(loan)[:interest_timeline]
      amounts = entries.map { |e| e[:period_interest] }

      assert_equal 3, amounts.length, "Expected 3 complete monthly entries"
      assert amounts.uniq.length == 1, "Expected equal monthly interest, got: #{amounts.inspect}"
    end
  end
end
