class CreateLoanPayments < ActiveRecord::Migration[7.2]
  def change
    create_table :loan_payments do |t|
      t.references :loan, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.datetime :paid_at, null: false
      t.text :note
      t.timestamps
    end
  end
end
