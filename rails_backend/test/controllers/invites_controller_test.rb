require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = create(:user)
    @group = create(:group, created_by: @alice)
  end

  test "shows a not-found state for an unknown token" do
    get "/invites/does-not-exist"
    assert_response :ok
    assert_select "h1", "Invite not found"
  end

  test "shows an account-needed state when the invited email has no user" do
    invite = @group.invite!("nobody@example.com")
    get "/invites/#{invite.token}"
    assert_select "h1", "Create a Square account first"
  end

  test "shows the password form when the invited email has an account" do
    create(:user, email: "friend@example.com", password: "password123")
    invite = @group.invite!("friend@example.com")

    get "/invites/#{invite.token}"
    assert_select "h1", "Join #{@group.name}"
    assert_select "form[action=?]", accept_invite_path(token: invite.token)
  end

  test "accepting with the wrong password re-shows the form with an error" do
    create(:user, email: "friend@example.com", password: "password123")
    invite = @group.invite!("friend@example.com")

    post "/invites/#{invite.token}/accept", params: { password: "nope" }
    assert_select "h1", "Join #{@group.name}"
    assert_select ".error"
    assert_equal "pending", invite.reload.status
  end

  test "accepting with the correct password joins the group" do
    friend = create(:user, email: "friend@example.com", password: "password123")
    invite = @group.invite!("friend@example.com")

    post "/invites/#{invite.token}/accept", params: { password: "password123" }
    assert_select "h1", "You're in!"
    assert_equal "accepted", invite.reload.status
    assert @group.reload.members.include?(friend)
  end

  test "an already-accepted invite shows the already-used state" do
    create(:user, email: "friend@example.com", password: "password123")
    invite = @group.invite!("friend@example.com")
    invite.accept_for_web!("password123")

    get "/invites/#{invite.token}"
    assert_select "h1", "This invite has already been used"
  end

  test "a revoked invite shows the revoked state and can't be accepted" do
    create(:user, email: "friend@example.com", password: "password123")
    invite = @group.invite!("friend@example.com")
    invite.revoke!

    get "/invites/#{invite.token}"
    assert_select "h1", "This invite was revoked"

    post "/invites/#{invite.token}/accept", params: { password: "password123" }
    assert_select "h1", "This invite was revoked"
    assert_equal "revoked", invite.reload.status
  end

  test "an expired invite shows the expired state" do
    invite = @group.invite!("friend@example.com")
    invite.update!(expires_at: 1.hour.ago)

    get "/invites/#{invite.token}"
    assert_select "h1", "This invite has expired"
  end
end
