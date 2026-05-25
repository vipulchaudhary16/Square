require "test_helper"

class LoanPaymentTest < ActiveSupport::TestCase
  setup do
    @lender  = create(:user)
    @contact = create(:contact, owner: @lender)
    @loan    = create(:loan, lender: @lender, contact: @contact, amount: 5000)
  end

  test "valid payment saves" do
    payment = LoanPayment.new(loan: @loan, amount: 1000, paid_at: Time.current)
    assert payment.valid?
  end

  test "requires amount" do
    payment = LoanPayment.new(loan: @loan, paid_at: Time.current)
    assert_not payment.valid?
    assert_includes payment.errors[:amount], "can't be blank"
  end

  test "requires paid_at" do
    payment = LoanPayment.new(loan: @loan, amount: 1000)
    assert_not payment.valid?
    assert_includes payment.errors[:paid_at], "can't be blank"
  end

  test "amount must be positive" do
    payment = LoanPayment.new(loan: @loan, amount: 0, paid_at: Time.current)
    assert_not payment.valid?
    assert_includes payment.errors[:amount], "must be greater than 0"
  end

  test "belongs to loan" do
    payment = create(:loan_payment, loan: @loan, amount: 500)
    assert_equal @loan, payment.loan
    assert_includes @loan.loan_payments, payment
  end
end
