require "test_helper"

class Api::V1::ExpensesControllerTest < ActionDispatch::IntegrationTest
  test "index filters to a single group even when the user has expenses in multiple groups" do
    alice = create(:user)
    bob   = create(:user)
    group1 = create(:group, created_by: alice, members: [bob])
    group2 = create(:group, created_by: alice, members: [bob])
    category = create(:category, user: alice)

    in_group1 = create(:expense, payer: alice, category: category, group: group1, amount: 30.0)
    create(:expense_participant, expense: in_group1, user: bob)

    in_group2 = create(:expense, payer: alice, category: category, group: group2, amount: 20.0)
    create(:expense_participant, expense: in_group2, user: bob)

    get "/api/expenses", params: { group_id: group1.id.to_s }, headers: auth_header(bob)

    assert_response :ok
    ids = JSON.parse(response.body).map { |e| e["id"] }
    assert_includes ids, in_group1.id.to_s
    assert_not_includes ids, in_group2.id.to_s
  end
end
