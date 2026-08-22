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

  test "returns delta_percent against the compare date range when given" do
    user = create(:user)
    category = create(:category, user: user)
    last_month = Date.today.prev_month
    create(:expense, payer: user, category: category, amount: 50.0, date: Date.today)
    create(:expense, payer: user, category: category, amount: 25.0, date: last_month)

    get "/api/analysis",
        params: {
          start_date: Date.today.iso8601,
          end_date: Date.today.iso8601,
          compare_start_date: last_month.iso8601,
          compare_end_date: last_month.iso8601
        },
        headers: auth_header(user)

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 100.0, body["spending"]["delta_percent"]
  end

  test "omits delta_percent when no compare date range is given" do
    user = create(:user)
    category = create(:category, user: user)
    create(:expense, payer: user, category: category, amount: 50.0, date: Date.today)

    get "/api/analysis",
        params: { start_date: Date.today.iso8601, end_date: Date.today.iso8601 },
        headers: auth_header(user)

    assert_response :ok
    body = JSON.parse(response.body)
    assert_not body["spending"].key?("delta_percent")
  end
end
