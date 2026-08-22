require "test_helper"

class DebtSettlementServiceTest < ActiveSupport::TestCase
  setup do
    @alice = create(:user)
    @bob   = create(:user)
    @category = create(:category, user: @alice)
  end

  test "equal split between payer and one participant" do
    expense = create(:expense, payer: @alice, category: @category, amount: 100.0, split_type: "EQUAL")
    create(:expense_participant, expense: expense, user: @alice)
    create(:expense_participant, expense: expense, user: @bob)
    create(:expense_split, expense: expense, user: @alice, amount: 50.0)
    create(:expense_split, expense: expense, user: @bob, amount: 50.0)

    debts = DebtSettlementService.compute([expense])
    assert_equal 1, debts.size
    assert_equal @bob.id, debts.first.from_id
    assert_equal @alice.id, debts.first.to_id
    assert_in_delta 50.0, debts.first.amount, 0.01
  end

  test "PERCENT split computes the correct amount owed, not the amount divided by 100 again" do
    expense = create(:expense, payer: @alice, category: @category, amount: 200.0, split_type: "PERCENT")
    create(:expense_split, expense: expense, user: @alice, amount: 150.0) # 75% resolved to dollars
    create(:expense_split, expense: expense, user: @bob,   amount: 50.0)  # 25% resolved to dollars

    debts = DebtSettlementService.compute([expense])
    assert_equal 1, debts.size
    assert_equal @bob.id, debts.first.from_id
    assert_equal @alice.id, debts.first.to_id
    assert_in_delta 50.0, debts.first.amount, 0.01
  end

  test "participants without explicit splits divide the amount equally" do
    expense = create(:expense, payer: @alice, category: @category, amount: 90.0, split_type: "EQUAL")
    create(:expense_participant, expense: expense, user: @alice)
    create(:expense_participant, expense: expense, user: @bob)

    debts = DebtSettlementService.compute([expense])
    assert_in_delta 45.0, debts.first.amount, 0.01
  end
end
