class BackfillCategoryIds < ActiveRecord::Migration[7.2]
  def up
    # Expenses — payer owns the category
    Expense.where(category_id: nil).find_each do |expense|
      owner = User.find_by(id: expense.payer_id)
      next unless owner
      cat = owner.categories.find_by("lower(name) = ?", expense.category.downcase) ||
            owner.categories.find_by(name: "General")
      expense.update_column(:category_id, cat&.id)
    end

    # Incomes
    Income.where(category_id: nil).find_each do |income|
      cat = income.user.categories.find_by("lower(name) = ?", income.category.to_s.downcase) ||
            income.user.categories.find_by(name: "General")
      income.update_column(:category_id, cat&.id)
    end

    # Budgets
    Budget.where(category_id: nil).find_each do |budget|
      if budget.category == "OVERALL"
        cat = budget.user.categories.find_by(name: "General")
      else
        cat = budget.user.categories.find_by("lower(name) = ?", budget.category.to_s.downcase) ||
              budget.user.categories.find_by(name: "General")
      end
      budget.update_column(:category_id, cat&.id)
    end
  end

  def down
    Expense.update_all(category_id: nil)
    Income.update_all(category_id: nil)
    Budget.update_all(category_id: nil)
  end
end
