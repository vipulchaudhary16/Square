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

  test "group_analysis 404s for a non-member" do
    outsider = create(:user)
    get "/api/groups/#{@group.id}/analysis", headers: auth_header(outsider)
    assert_response :not_found
  end
end
