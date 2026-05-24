class CreateExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :expenses do |t|
      t.string     :description, null: false
      t.decimal    :amount,      null: false, precision: 12, scale: 2
      t.string     :category,    null: false, default: ""
      t.datetime   :date,        null: false
      t.references :payer,       null: false, foreign_key: { to_table: :users }
      t.references :group,       null: true,  foreign_key: true
      t.string     :split_type
      t.timestamps
    end
    add_index :expenses, :date
  end
end
