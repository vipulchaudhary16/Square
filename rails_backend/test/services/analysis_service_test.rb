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

  test "summarize omits delta_percent entirely when no previous_scope is given" do
    e1 = create(:expense, payer: @user, category: @food, amount: 60.0)
    result = AnalysisService.summarize(Expense.where(id: e1.id))
    assert_not result.key?(:delta_percent)
  end

  test "summarize computes delta_percent against previous_scope" do
    e1 = create(:expense, payer: @user, category: @food, amount: 120.0)
    previous = create(:expense, payer: @user, category: @food, amount: 100.0)

    result = AnalysisService.summarize(
      Expense.where(id: e1.id),
      previous_scope: Expense.where(id: previous.id),
    )

    assert_equal 20.0, result[:delta_percent]
  end

  test "summarize returns a nil delta_percent when the previous period had a zero total" do
    e1 = create(:expense, payer: @user, category: @food, amount: 60.0)

    result = AnalysisService.summarize(Expense.where(id: e1.id), previous_scope: Expense.none)

    assert_nil result[:delta_percent]
  end

  test "summarize computes a per-category delta_percent against the matching previous category" do
    food_now = create(:expense, payer: @user, category: @food, amount: 120.0)
    travel_now = create(:expense, payer: @user, category: @travel, amount: 50.0)

    food_before = create(:expense, payer: @user, category: @food, amount: 100.0)
    # No previous Travel expense at all — Travel should get a nil delta, not divide-by-zero.

    result = AnalysisService.summarize(
      Expense.where(id: [food_now.id, travel_now.id]),
      previous_scope: Expense.where(id: food_before.id),
    )

    food_row = result[:by_category].find { |c| c[:category_name] == "Food" }
    travel_row = result[:by_category].find { |c| c[:category_name] == "Travel" }
    assert_equal 20.0, food_row[:delta_percent]
    assert_nil travel_row[:delta_percent]
  end

  test "summarize omits per-category delta_percent entirely when no previous_scope is given" do
    e1 = create(:expense, payer: @user, category: @food, amount: 60.0)
    result = AnalysisService.summarize(Expense.where(id: e1.id))
    food_row = result[:by_category].find { |c| c[:category_name] == "Food" }
    assert_not food_row.key?(:delta_percent)
  end
end
