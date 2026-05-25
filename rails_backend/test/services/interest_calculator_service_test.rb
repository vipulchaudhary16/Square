require "test_helper"

class InterestCalculatorServiceTest < ActiveSupport::TestCase
  def build_loan(overrides = {})
    lender  = create(:user)
    contact = create(:contact, owner: lender)
    create(:loan, { lender: lender, contact: contact,
                    amount: 10_000, date: 10.days.ago,
                    status: "PENDING", interest_mode: "none" }.merge(overrides))
  end

  # --- none mode ---

  test "mode none: outstanding = amount, zero interest" do
    loan   = build_loan(amount: 5000, interest_mode: "none")
    result = InterestCalculatorService.new(loan).call
    assert_equal 5000.0,  result[:outstanding]
    assert_equal 0.0,     result[:accrued_interest]
    assert_equal 5000.0,  result[:total_due]
    assert_equal 0.0,     result[:daily_rate]
    assert_empty          result[:interest_timeline]
  end

  test "mode none: payment reduces outstanding" do
    loan = build_loan(amount: 5000, interest_mode: "none")
    create(:loan_payment, loan: loan, amount: 2000)
    result = InterestCalculatorService.new(loan).call
    assert_equal 3000.0, result[:outstanding]
    assert_equal 3000.0, result[:total_due]
  end

  # --- from_start + principal basis ---

  test "mode from_start principal: accrued_interest = outstanding * daily_rate * days" do
    loan = build_loan(
      amount: 10_000, date: 10.days.ago,
      interest_mode: "from_start",
      interest_rate: 0.01, interest_period: "daily", interest_basis: "principal"
    )
    result = InterestCalculatorService.new(loan).call
    assert_equal 10_000.0, result[:outstanding]
    assert_in_delta 1000.0, result[:accrued_interest], 0.01
    assert_in_delta 11_000.0, result[:total_due], 0.01
    assert_equal 0.01, result[:daily_rate]
    assert_equal 10, result[:interest_timeline].length
  end

  test "mode from_start principal: monthly rate normalised to daily" do
    loan = build_loan(
      amount: 30_000, date: 30.days.ago,
      interest_mode: "from_start",
      interest_rate: 0.03, interest_period: "monthly", interest_basis: "principal"
    )
    result = InterestCalculatorService.new(loan).call
    expected_daily_rate = 0.03 / 30.0
    assert_in_delta expected_daily_rate, result[:daily_rate], 0.000001
    expected_interest = 30_000 * expected_daily_rate * 30
    assert_in_delta expected_interest, result[:accrued_interest], 0.01
  end

  test "mode from_start principal: annual rate normalised to daily" do
    loan = build_loan(
      amount: 36_500, date: 365.days.ago,
      interest_mode: "from_start",
      interest_rate: 0.365, interest_period: "annual", interest_basis: "principal"
    )
    result = InterestCalculatorService.new(loan).call
    expected_daily_rate = 0.365 / 365.0
    assert_in_delta expected_daily_rate, result[:daily_rate], 0.000001
    expected_interest = 36_500 * expected_daily_rate * 365
    assert_in_delta expected_interest, result[:accrued_interest], 0.01
  end

  # --- from_start + total (compound) basis ---

  test "mode from_start total: compound interest formula" do
    loan = build_loan(
      amount: 10_000, date: 10.days.ago,
      interest_mode: "from_start",
      interest_rate: 0.01, interest_period: "daily", interest_basis: "total"
    )
    result = InterestCalculatorService.new(loan).call
    expected = 10_000 * ((1.01**10) - 1)
    assert_in_delta expected, result[:accrued_interest], 0.01
  end

  # --- penalty mode ---

  test "penalty mode: zero interest when not overdue" do
    loan = build_loan(
      amount: 5000, date: 10.days.ago,
      interest_mode: "penalty", due_date: 3.days.from_now,
      interest_rate: 0.02, interest_period: "daily", interest_basis: "principal"
    )
    result = InterestCalculatorService.new(loan).call
    assert_equal 0.0, result[:accrued_interest]
    assert_empty result[:interest_timeline]
  end

  test "penalty mode: interest accrues after due_date" do
    loan = build_loan(
      amount: 5000, date: 20.days.ago,
      interest_mode: "penalty", due_date: 10.days.ago,
      interest_rate: 0.02, interest_period: "daily", interest_basis: "principal"
    )
    result = InterestCalculatorService.new(loan).call
    assert_in_delta 5000 * 0.02 * 10, result[:accrued_interest], 0.01
    assert_equal 10, result[:interest_timeline].length
  end

  # --- timeline structure ---

  test "timeline entries have date, daily_interest, cumulative" do
    loan = build_loan(
      amount: 1000, date: 3.days.ago,
      interest_mode: "from_start",
      interest_rate: 0.01, interest_period: "daily", interest_basis: "principal"
    )
    result  = InterestCalculatorService.new(loan).call
    entries = result[:interest_timeline]
    assert_equal 3, entries.length
    assert_respond_to entries.first, :[]
    assert entries.first[:date].is_a?(String)
    assert entries.first[:daily_interest] > 0
    assert_in_delta entries.last[:cumulative], result[:accrued_interest], 0.01
  end
end
