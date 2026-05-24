class FinalizeCategoryMigration < ActiveRecord::Migration[7.2]
  def up
    # Make category_id not null
    change_column_null :expenses, :category_id, false
    change_column_null :incomes,  :category_id, false
    change_column_null :budgets,  :category_id, false

    # Drop old string columns
    remove_column :expenses, :category
    remove_column :incomes,  :category
    remove_column :budgets,  :category

    # Replace budget unique index (category string → category_id)
    remove_index :budgets, name: "index_budgets_on_user_id_and_category_and_month", if_exists: true
    add_index :budgets, [:user_id, :category_id, :month], unique: true, name: "index_budgets_on_user_id_and_category_id_and_month"
  end

  def down
    add_column :expenses, :category, :string, default: "", null: false
    add_column :incomes,  :category, :string, default: "", null: false
    add_column :budgets,  :category, :string, default: "", null: false
    change_column_null :expenses, :category_id, true
    change_column_null :incomes,  :category_id, true
    change_column_null :budgets,  :category_id, true
  end
end
