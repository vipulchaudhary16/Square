require "test_helper"

class SessionServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test "issue_for returns an access token and a refresh token" do
    session = SessionService.issue_for(@user)
    assert session[:access_token].present?
    assert session[:refresh_token].present?
  end

  test "refresh rotates to a new refresh token and keeps the access token valid" do
    first = SessionService.issue_for(@user)
    second = SessionService.refresh(first[:refresh_token])

    assert_not_equal first[:refresh_token], second[:refresh_token]
    decoded = JwtService.decode(second[:access_token])
    assert_equal @user.id.to_s, decoded[:user_id]
  end

  test "replaying an already-rotated refresh token raises Reused and kills the session" do
    first = SessionService.issue_for(@user)
    second = SessionService.refresh(first[:refresh_token])

    assert_raises(SessionService::Reused) { SessionService.refresh(first[:refresh_token]) }

    # The whole family was revoked as a theft response — the rotated-to
    # token that would otherwise still be valid is dead too.
    assert_raises(SessionService::Invalid) { SessionService.refresh(second[:refresh_token]) }
  end

  test "refresh with an unknown token raises Invalid" do
    assert_raises(SessionService::Invalid) { SessionService.refresh("not-a-real-token") }
  end

  test "revoke invalidates the refresh token" do
    session = SessionService.issue_for(@user)
    SessionService.revoke(session[:refresh_token])

    assert_raises(SessionService::Invalid) { SessionService.refresh(session[:refresh_token]) }
  end

  test "revoke_all_for kills every session for a user" do
    a = SessionService.issue_for(@user)
    b = SessionService.issue_for(@user)

    SessionService.revoke_all_for(@user)

    assert_raises(SessionService::Invalid) { SessionService.refresh(a[:refresh_token]) }
    assert_raises(SessionService::Invalid) { SessionService.refresh(b[:refresh_token]) }
  end
end
