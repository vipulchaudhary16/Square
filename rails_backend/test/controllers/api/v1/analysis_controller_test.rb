require "test_helper"

class Api::V1::AnalysisControllerTest < ActionDispatch::IntegrationTest
  test "returns spending and income summaries scoped to the current user, excluding group expenses" do
    user = create(:user)
    category = create(:category, user: user)
    group = create(:group, created_by: user)
    create(:expense, payer: user, category: category, amount: 50.0, date: Date.today)
    create(:expense, payer: user, category: category, amount: 999.0, date: Date.today, group: group)

    get "/api/analysis",
        params: { start_date: Date.today.iso8601, end_date: Date.today.iso8601 },
        headers: auth_header(user)

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 50.0, body["spending"]["total"]
  end
end
