class CreateIncomes < ActiveRecord::Migration[7.2]
  def change
    create_table :incomes do |t|
      t.references :user,        null: false, foreign_key: true
      t.string     :source,      null: false
      t.decimal    :amount,      null: false, precision: 12, scale: 2
      t.string     :category,    null: false, default: ""
      t.datetime   :date,        null: false
      t.text       :description
      t.timestamps
    end
    add_index :incomes, [:user_id, :date]
  end
end
