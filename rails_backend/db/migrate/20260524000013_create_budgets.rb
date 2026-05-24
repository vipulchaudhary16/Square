class CreateBudgets < ActiveRecord::Migration[7.2]
  def change
    create_table :budgets do |t|
      t.references :user,     null: false, foreign_key: true
      t.string     :category, null: false
      t.decimal    :amount,   null: false, precision: 12, scale: 2
      t.string     :month,    null: false
      t.timestamps
    end
    add_index :budgets, [:user_id, :category, :month], unique: true
  end
end
