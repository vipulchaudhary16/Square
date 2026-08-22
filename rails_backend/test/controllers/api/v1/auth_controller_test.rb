require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, password: "password123")
  end

  test "login returns an access token and a refresh token" do
    post "/api/auth/login", params: { email: @user.email, password: "password123" }
    assert_response :ok

    body = JSON.parse(response.body)
    assert body["access_token"].present?
    assert body["refresh_token"].present?
    assert_equal @user.id.to_s, body["user"]["id"]
  end

  test "refresh exchanges a valid refresh token for a new pair" do
    login = SessionService.issue_for(@user)

    post "/api/auth/refresh", params: { refresh_token: login[:refresh_token] }
    assert_response :ok

    body = JSON.parse(response.body)
    assert_not_equal login[:refresh_token], body["refresh_token"]
  end

  test "refresh rejects a replayed (already-rotated) refresh token" do
    login = SessionService.issue_for(@user)
    SessionService.refresh(login[:refresh_token])

    post "/api/auth/refresh", params: { refresh_token: login[:refresh_token] }
    assert_response :unauthorized
  end

  test "logout revokes the refresh token and the current access token" do
    login = SessionService.issue_for(@user)

    post "/api/auth/logout",
         params: { refresh_token: login[:refresh_token] }.to_json,
         headers: { "Authorization" => "Bearer #{login[:access_token]}", "Content-Type" => "application/json" }
    assert_response :no_content

    # The refresh token no longer works.
    post "/api/auth/refresh", params: { refresh_token: login[:refresh_token] }
    assert_response :unauthorized

    # The access token that was used to log out is immediately denylisted,
    # even though it hasn't naturally expired yet.
    get "/api/auth/me", headers: { "Authorization" => "Bearer #{login[:access_token]}" }
    assert_response :unauthorized
  end

  test "logout_all revokes every session for the user" do
    a = SessionService.issue_for(@user)
    b = SessionService.issue_for(@user)

    post "/api/auth/logout-all", headers: auth_header(@user)
    assert_response :no_content

    post "/api/auth/refresh", params: { refresh_token: a[:refresh_token] }
    assert_response :unauthorized
    post "/api/auth/refresh", params: { refresh_token: b[:refresh_token] }
    assert_response :unauthorized
  end
end
