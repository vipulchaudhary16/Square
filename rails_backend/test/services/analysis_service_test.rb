require "test_helper"

class AnalysisServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @food = create(:category, user: @user, name: "Food")
    @travel = create(:category, user: @user, name: "Travel")
  end

  test "summarize totals and buckets by category using the default value (record.amount)" do
    e1 = create(:expense, payer: @user, category: @food, amount: 60.0)
    e2 = create(:expense, payer: @user, category: @travel, amount: 40.0)

    result = AnalysisService.summarize(Expense.where(id: [e1.id, e2.id]))

    assert_equal 100.0, result[:total]
    assert_equal 2, result[:count]
    food_row = result[:by_category].find { |c| c[:category_name] == "Food" }
    assert_equal 60.0, food_row[:amount]
    assert_equal 60.0, food_row[:percent]
  end

  test "summarize accepts a custom value extractor" do
    e1 = create(:expense, payer: @user, category: @food, amount: 100.0)
    other = create(:user)
    create(:expense_split, expense: e1, user: other, amount: 30.0)

    result = AnalysisService.summarize(Expense.where(id: e1.id), value: ->(e) { e.split_for(other.id) })

    assert_equal 30.0, result[:total]
  end

  test "summarize returns 0.0 percent when total is zero" do
    result = AnalysisService.summarize(Expense.none)
    assert_equal 0.0, result[:total]
    assert_equal 0, result[:count]
    assert_equal [], result[:by_category]
  end
end
