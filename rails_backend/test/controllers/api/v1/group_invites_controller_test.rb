require "test_helper"

class Api::V1::GroupInvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = create(:user)
    @bob   = create(:user)
    @group = create(:group, created_by: @alice, members: [@bob])
    @invite = @group.invite!("friend@example.com")
  end

  test "the group creator can revoke a pending invite" do
    post "/api/group_invites/#{@invite.id}/revoke", headers: auth_header(@alice)
    assert_response :ok
    assert_equal "revoked", JSON.parse(response.body)["status"]
    assert_equal "revoked", @invite.reload.status
  end

  test "a non-creator member cannot revoke an invite" do
    post "/api/group_invites/#{@invite.id}/revoke", headers: auth_header(@bob)
    assert_response :forbidden
    assert_equal "pending", @invite.reload.status
  end

  test "a non-member cannot revoke an invite" do
    outsider = create(:user)
    post "/api/group_invites/#{@invite.id}/revoke", headers: auth_header(outsider)
    assert_response :forbidden
  end
end
