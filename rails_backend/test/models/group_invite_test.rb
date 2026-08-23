require "test_helper"

class GroupInviteTest < ActiveSupport::TestCase
  setup do
    @alice = create(:user)
    @group = create(:group, created_by: @alice)
  end

  test "invite! creates a pending invite expiring in 48 hours" do
    invite = @group.invite!("friend@example.com")
    assert_equal "pending", invite.status
    assert_in_delta 48.hours.from_now.to_i, invite.expires_at.to_i, 5
  end

  test "display_status reports expired for a pending invite past its expiry, without changing the stored status" do
    invite = @group.invite!("friend@example.com")
    invite.update!(expires_at: 1.hour.ago)

    assert invite.expired?
    assert_equal "expired", invite.display_status
    assert_equal "pending", invite.status
  end

  test "accept_for_web! fails without a matching account" do
    invite = @group.invite!("nobody@example.com")
    assert_not invite.accept_for_web!("whatever")
    assert_equal "pending", invite.reload.status
  end

  test "accept_for_web! fails with the wrong password" do
    create(:user, email: "friend@example.com", password: "password123")
    invite = @group.invite!("friend@example.com")

    assert_not invite.accept_for_web!("wrong")
    assert_equal "pending", invite.reload.status
  end

  test "accept_for_web! joins the group with the right password" do
    friend = create(:user, email: "friend@example.com", password: "password123")
    invite = @group.invite!("friend@example.com")

    assert invite.accept_for_web!("password123")
    assert_equal "accepted", invite.reload.status
    assert @group.reload.members.include?(friend)
  end

  test "invite! raises if the email already belongs to a group member" do
    friend = create(:user, email: "friend@example.com")
    @group.group_memberships.create!(user: friend)

    assert_raises(Group::AlreadyMemberError) { @group.invite!("friend@example.com") }
  end

  test "invite! raises for a member email regardless of case" do
    friend = create(:user, email: "friend@example.com")
    @group.group_memberships.create!(user: friend)

    assert_raises(Group::AlreadyMemberError) { @group.invite!("FRIEND@example.com") }
  end

  test "revoke! sets status to revoked" do
    invite = @group.invite!("friend@example.com")
    invite.revoke!
    assert_equal "revoked", invite.reload.status
  end
end
