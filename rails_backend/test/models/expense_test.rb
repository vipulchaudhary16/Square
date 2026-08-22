require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  setup do
    @payer = create(:user)
    @participant = create(:user)
    @outsider = create(:user)
    @category = create(:category, user: @payer)
  end

  test "split_for returns the stored split amount when expense_splits exist" do
    expense = create(:expense, payer: @payer, category: @category, amount: 100.0, split_type: "EXACT")
    create(:expense_split, expense: expense, user: @payer, amount: 60.0)
    create(:expense_split, expense: expense, user: @participant, amount: 40.0)

    assert_equal 40.0, expense.split_for(@participant.id)
    assert_equal 60.0, expense.split_for(@payer.id)
  end

  test "split_for divides equally among participants when no splits exist" do
    expense = create(:expense, payer: @payer, category: @category, amount: 90.0, split_type: "EQUAL")
    create(:expense_participant, expense: expense, user: @payer)
    create(:expense_participant, expense: expense, user: @participant)
    create(:expense_participant, expense: expense, user: @outsider)

    assert_equal 30.0, expense.split_for(@participant.id)
  end

  test "split_for returns 0 for a user with no split and no participant row" do
    expense = create(:expense, payer: @payer, category: @category, amount: 100.0)
    create(:expense_participant, expense: expense, user: @payer)

    assert_equal 0.0, expense.split_for(@outsider.id)
  end
end
