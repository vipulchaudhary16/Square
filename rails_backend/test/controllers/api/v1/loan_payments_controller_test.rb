require "test_helper"

class Api::V1::LoanPaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lender   = create(:user)
    @borrower = create(:user)
    @contact  = create(:contact, owner: @lender, linked_user: @borrower)
    @loan     = create(:loan, lender: @lender, borrower: @borrower,
                              contact: @contact, amount: 5000,
                              status: "PENDING", interest_mode: "none")
  end

  # --- GET index ---

  test "lender can list payments" do
    create(:loan_payment, loan: @loan, amount: 1000)
    get "/api/loans/#{@loan.id}/payments", headers: auth_header(@lender)
    assert_response :ok
    assert_equal 1, JSON.parse(response.body).length
  end

  test "borrower can list payments" do
    create(:loan_payment, loan: @loan, amount: 1000)
    get "/api/loans/#{@loan.id}/payments", headers: auth_header(@borrower)
    assert_response :ok
  end

  test "unrelated user cannot see payments" do
    get "/api/loans/#{@loan.id}/payments", headers: auth_header(create(:user))
    assert_response :not_found
  end

  # --- POST create ---

  test "lender can record a partial payment" do
    post "/api/loans/#{@loan.id}/payments",
         params: { amount: 2000, paid_at: Date.today.iso8601 }.to_json,
         headers: auth_header(@lender)
    assert_response :created
    @loan.reload
    assert_equal "PARTIAL", @loan.status
    assert_equal 1, @loan.loan_payments.count
  end

  test "recording full amount sets status to PAID" do
    post "/api/loans/#{@loan.id}/payments",
         params: { amount: 5000, paid_at: Date.today.iso8601 }.to_json,
         headers: auth_header(@lender)
    assert_response :created
    assert_equal "PAID", @loan.reload.status
  end

  test "recording payment that exactly clears outstanding sets PAID" do
    create(:loan_payment, loan: @loan, amount: 3000)
    post "/api/loans/#{@loan.id}/payments",
         params: { amount: 2000, paid_at: Date.today.iso8601 }.to_json,
         headers: auth_header(@lender)
    assert_response :created
    assert_equal "PAID", @loan.reload.status
  end

  test "borrower cannot record payment" do
    post "/api/loans/#{@loan.id}/payments",
         params: { amount: 1000, paid_at: Date.today.iso8601 }.to_json,
         headers: auth_header(@borrower)
    assert_response :forbidden
  end

  test "add_interest_to_income creates income record" do
    loan = create(:loan, lender: @lender, borrower: @borrower, contact: @contact,
                         amount: 10_000, date: 10.days.ago,
                         interest_mode: "from_start",
                         interest_rate: 0.01, interest_period: "daily",
                         interest_basis: "principal", status: "PENDING")
    assert_difference("Income.count", 1) do
      post "/api/loans/#{loan.id}/payments",
           params: {
             amount:                5000,
             paid_at:               Date.today.iso8601,
             add_interest_to_income: true
           }.to_json,
           headers: auth_header(@lender)
    end
    assert_response :created
    income = Income.last
    assert_includes income.source, @contact.name
  end

  test "add_interest_to_income false does not create income" do
    loan = create(:loan, lender: @lender, borrower: @borrower, contact: @contact,
                         amount: 10_000, date: 10.days.ago,
                         interest_mode: "from_start",
                         interest_rate: 0.01, interest_period: "daily",
                         interest_basis: "principal", status: "PENDING")
    assert_no_difference("Income.count") do
      post "/api/loans/#{loan.id}/payments",
           params: {
             amount:                5000,
             paid_at:               Date.today.iso8601,
             add_interest_to_income: false
           }.to_json,
           headers: auth_header(@lender)
    end
  end
end
