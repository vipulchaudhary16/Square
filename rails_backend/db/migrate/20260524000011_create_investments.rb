class CreateInvestments < ActiveRecord::Migration[7.2]
  def change
    create_table :investments do |t|
      t.references :user,            null: false, foreign_key: true
      t.string     :name,            null: false
      t.string     :investment_type, null: false
      t.decimal    :amount_invested, null: false, precision: 12, scale: 2
      t.decimal    :current_value,   null: false, precision: 12, scale: 2
      t.datetime   :date,            null: false
      t.text       :description
      t.timestamps
    end
    add_index :investments, [:user_id, :date]
  end
end
