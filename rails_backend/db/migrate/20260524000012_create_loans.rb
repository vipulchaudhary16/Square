class CreateLoans < ActiveRecord::Migration[7.2]
  def change
    create_table :loans do |t|
      t.references :user,              null: false, foreign_key: true
      t.string     :counterparty_name, null: false
      t.string     :loan_type,         null: false
      t.decimal    :amount,            null: false, precision: 12, scale: 2
      t.datetime   :date,              null: false
      t.datetime   :due_date
      t.string     :status,            null: false, default: "PENDING"
      t.text       :description
      t.timestamps
    end
    add_index :loans, [:user_id, :status]
  end
end
