class CreateExpenseSplits < ActiveRecord::Migration[7.2]
  def change
    create_table :expense_splits do |t|
      t.references :expense, null: false, foreign_key: true
      t.references :user,    null: false, foreign_key: true
      t.decimal    :amount,  null: false, precision: 12, scale: 2
      t.timestamps
    end
    add_index :expense_splits, [:expense_id, :user_id], unique: true
  end
end
