require "test_helper"

class Api::V1::GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = create(:user)
    @bob   = create(:user)
    @group = create(:group, created_by: @alice, members: [@bob])
    @category = create(:category, user: @alice)
  end

  test "group_analysis returns total_expense for the whole group and your_share for the current user" do
    e1 = create(:expense, payer: @alice, category: @category, group: @group, amount: 100.0, split_type: "EQUAL", date: Date.today)
    create(:expense_participant, expense: e1, user: @alice)
    create(:expense_participant, expense: e1, user: @bob)
    create(:expense_split, expense: e1, user: @alice, amount: 50.0)
    create(:expense_split, expense: e1, user: @bob, amount: 50.0)

    get "/api/groups/#{@group.id}/analysis",
        params: { start_date: Date.today.iso8601, end_date: Date.today.iso8601 },
        headers: auth_header(@bob)

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 100.0, body["total_expense"]["total"]
    assert_equal 50.0, body["your_share"]["total"]
  end

  test "group_analysis excludes expenses the current user is not part of from your_share but keeps them in total_expense" do
    charlie = create(:user)
    other_expense = create(:expense, payer: @alice, category: @category, group: @group, amount: 40.0, date: Date.today)
    create(:expense_participant, expense: other_expense, user: @alice)
    create(:expense_participant, expense: other_expense, user: charlie)
    create(:expense_split, expense: other_expense, user: @alice, amount: 20.0)
    create(:expense_split, expense: other_expense, user: charlie, amount: 20.0)

    get "/api/groups/#{@group.id}/analysis",
        params: { start_date: Date.today.iso8601, end_date: Date.today.iso8601 },
        headers: auth_header(@bob)

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 40.0, body["total_expense"]["total"]
    assert_equal 0.0, body["your_share"]["total"]
  end

  test "group_analysis only counts expenses within the given date range" do
    in_range = create(:expense, payer: @alice, category: @category, group: @group, amount: 50.0, date: Date.today)
    create(:expense_participant, expense: in_range, user: @bob)
    create(:expense_split, expense: in_range, user: @bob, amount: 50.0)

    out_of_range = create(:expense, payer: @alice, category: @category, group: @group, amount: 999.0, date: 30.days.ago)
    create(:expense_participant, expense: out_of_range, user: @bob)
    create(:expense_split, expense: out_of_range, user: @bob, amount: 999.0)

    get "/api/groups/#{@group.id}/analysis",
        params: { start_date: Date.today.iso8601, end_date: Date.today.iso8601 },
        headers: auth_header(@bob)

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 50.0, body["total_expense"]["total"]
    assert_equal 50.0, body["your_share"]["total"]
  end

  test "group_analysis returns delta_percent for both sides against the compare date range" do
    last_month = Date.today.prev_month

    current = create(:expense, payer: @alice, category: @category, group: @group, amount: 100.0, date: Date.today)
    create(:expense_participant, expense: current, user: @alice)
    create(:expense_participant, expense: current, user: @bob)
    create(:expense_split, expense: current, user: @alice, amount: 50.0)
    create(:expense_split, expense: current, user: @bob, amount: 50.0)

    previous = create(:expense, payer: @alice, category: @category, group: @group, amount: 50.0, date: last_month)
    create(:expense_participant, expense: previous, user: @alice)
    create(:expense_participant, expense: previous, user: @bob)
    create(:expense_split, expense: previous, user: @alice, amount: 25.0)
    create(:expense_split, expense: previous, user: @bob, amount: 25.0)

    get "/api/groups/#{@group.id}/analysis",
        params: {
          start_date: Date.today.iso8601,
          end_date: Date.today.iso8601,
          compare_start_date: last_month.iso8601,
          compare_end_date: last_month.iso8601
        },
        headers: auth_header(@bob)

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 100.0, body["total_expense"]["delta_percent"]
    assert_equal 100.0, body["your_share"]["delta_percent"]
  end

  test "group_analysis omits delta_percent when no compare date range is given" do
    e1 = create(:expense, payer: @alice, category: @category, group: @group, amount: 100.0, date: Date.today)
    create(:expense_participant, expense: e1, user: @bob)
    create(:expense_split, expense: e1, user: @bob, amount: 100.0)

    get "/api/groups/#{@group.id}/analysis",
        params: { start_date: Date.today.iso8601, end_date: Date.today.iso8601 },
        headers: auth_header(@bob)

    assert_response :ok
    body = JSON.parse(response.body)
    assert_not body["total_expense"].key?("delta_percent")
    assert_not body["your_share"].key?("delta_percent")
  end

  test "group_analysis 404s for a non-member" do
    outsider = create(:user)
    get "/api/groups/#{@group.id}/analysis", headers: auth_header(outsider)
    assert_response :not_found
  end

  # --- invite / group_invites (owner-only) ---

  test "the group creator can send an invite" do
    post "/api/groups/#{@group.id}/invite",
         params: { email: "friend@example.com" }.to_json,
         headers: auth_header(@alice)
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "friend@example.com", body["email"]
    assert_equal "pending", body["status"]
    assert_includes body["link"], "/invites/"
  end

  test "a non-creator member cannot send an invite" do
    post "/api/groups/#{@group.id}/invite",
         params: { email: "friend@example.com" }.to_json,
         headers: auth_header(@bob)
    assert_response :forbidden
  end

  test "cannot invite an email that already belongs to a group member" do
    post "/api/groups/#{@group.id}/invite",
         params: { email: @bob.email }.to_json,
         headers: auth_header(@alice)
    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_match(/already a member/, body["error"])
  end

  test "the group creator can list invites, a non-creator member cannot" do
    @group.invite!("friend@example.com")

    get "/api/groups/#{@group.id}/invites", headers: auth_header(@alice)
    assert_response :ok
    assert_equal 1, JSON.parse(response.body).length

    get "/api/groups/#{@group.id}/invites", headers: auth_header(@bob)
    assert_response :forbidden
  end
end
