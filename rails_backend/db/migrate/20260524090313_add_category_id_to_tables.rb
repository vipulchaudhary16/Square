class AddCategoryIdToTables < ActiveRecord::Migration[7.2]
  def change
    add_reference :expenses, :category, foreign_key: true, null: true
    add_reference :incomes,  :category, foreign_key: true, null: true
    add_reference :budgets,  :category, foreign_key: true, null: true
  end
end
