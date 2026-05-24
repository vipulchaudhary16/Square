require "test_helper"

class Api::V1::ContactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @headers = auth_header(@user)
  end

  test "GET /api/contacts returns user contacts" do
    create(:contact, owner: @user, name: "Rahul")
    create(:contact, name: "Priya") # belongs to another user — should not appear

    get "/api/contacts", headers: @headers
    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal "Rahul", body.first["name"]
  end

  test "GET /api/contacts/search returns contacts and platform users" do
    create(:contact, owner: @user, name: "Rahul Kumar")
    platform_user = create(:user, username: "neha_s", email: "neha@test.com")

    get "/api/contacts/search", params: { q: "neha" }, headers: @headers
    assert_response :ok
    body = JSON.parse(response.body)
    assert_includes body["platform_users"].map { |u| u["id"] }, platform_user.id.to_s
  end

  test "GET /api/contacts/search returns empty for short query" do
    get "/api/contacts/search", params: { q: "a" }, headers: @headers
    assert_response :ok
    assert_equal [], JSON.parse(response.body)
  end

  test "POST /api/contacts creates off-platform contact" do
    post "/api/contacts", params: { name: "Rahul", phone: "9876543210" }.to_json, headers: @headers
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Rahul", body["name"]
    assert_equal false, body["on_platform"]
  end

  test "POST /api/contacts creates on-platform contact with linked_user_id" do
    platform_user = create(:user)
    post "/api/contacts",
         params: { name: platform_user.display_name, linked_user_id: platform_user.id }.to_json,
         headers: @headers
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal true, body["on_platform"]
    assert_equal platform_user.id.to_s, body["linked_user_id"]
  end

  test "GET /api/contacts/:id/loans returns all loans with that contact" do
    contact = create(:contact, owner: @user)
    loan1 = create(:loan, lender: @user, contact: contact)
    _loan_other = create(:loan) # different contact — should not appear

    get "/api/contacts/#{contact.id}/loans", headers: @headers
    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 1, body["loans"].length
    assert_equal loan1.id.to_s, body["loans"].first["id"]
  end

  test "GET /api/contacts/:id/loans returns 404 for wrong owner" do
    other_user = create(:user)
    contact = create(:contact, owner: other_user)

    get "/api/contacts/#{contact.id}/loans", headers: @headers
    assert_response :not_found
  end
end
