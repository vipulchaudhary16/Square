require "test_helper"

class Api::V1::LoansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lender   = create(:user)
    @borrower = create(:user)
    @contact  = create(:contact, owner: @lender, linked_user: @borrower)
    @loan     = create(:loan, lender: @lender, borrower: @borrower, contact: @contact)
  end

  # --- index ---

  test "lender sees their loans in index" do
    get "/api/loans", headers: auth_header(@lender)
    assert_response :ok
    ids = JSON.parse(response.body).map { |l| l["id"] }
    assert_includes ids, @loan.id.to_s
  end

  test "borrower sees loans they are borrowing in index" do
    get "/api/loans", headers: auth_header(@borrower)
    assert_response :ok
    ids = JSON.parse(response.body).map { |l| l["id"] }
    assert_includes ids, @loan.id.to_s
  end

  test "unrelated user does not see loan in index" do
    other = create(:user)
    get "/api/loans", headers: auth_header(other)
    assert_response :ok
    assert_empty JSON.parse(response.body)
  end

  # --- create ---

  test "lender can create a loan with contact_id" do
    post "/api/loans",
         params: {
           contact_id:    @contact.id,
           amount:        3000,
           date:          Date.today.iso8601,
           interest_mode: "none",
           description:   "Test"
         }.to_json,
         headers: auth_header(@lender)
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "PENDING", body["status"]
    assert_equal @contact.id.to_s, body["contact_id"]
  end

  # --- show ---

  test "lender can view loan detail" do
    get "/api/loans/#{@loan.id}", headers: auth_header(@lender)
    assert_response :ok
    assert_equal @loan.id.to_s, JSON.parse(response.body)["loan"]["id"]
  end

  test "borrower can view loan detail (read-only access)" do
    get "/api/loans/#{@loan.id}", headers: auth_header(@borrower)
    assert_response :ok
  end

  test "unrelated user cannot view loan" do
    get "/api/loans/#{@loan.id}", headers: auth_header(create(:user))
    assert_response :not_found
  end

  # --- update ---

  test "lender can update loan" do
    patch "/api/loans/#{@loan.id}",
          params: { description: "Updated" }.to_json,
          headers: auth_header(@lender)
    assert_response :ok
  end

  test "borrower cannot update loan" do
    patch "/api/loans/#{@loan.id}",
          params: { description: "Hack" }.to_json,
          headers: auth_header(@borrower)
    assert_response :forbidden
  end

  # --- destroy ---

  test "lender can delete loan" do
    delete "/api/loans/#{@loan.id}", headers: auth_header(@lender)
    assert_response :ok
  end

  test "borrower cannot delete loan" do
    delete "/api/loans/#{@loan.id}", headers: auth_header(@borrower)
    assert_response :forbidden
  end

  # --- confirmation ---

  test "borrower can update confirmation_status" do
    patch "/api/loans/#{@loan.id}/confirmation",
          params: { confirmation_status: "confirmed" }.to_json,
          headers: auth_header(@borrower)
    assert_response :ok
    assert_equal "confirmed", @loan.reload.confirmation_status
  end

  test "lender cannot update confirmation_status" do
    patch "/api/loans/#{@loan.id}/confirmation",
          params: { confirmation_status: "confirmed" }.to_json,
          headers: auth_header(@lender)
    assert_response :forbidden
  end
end
