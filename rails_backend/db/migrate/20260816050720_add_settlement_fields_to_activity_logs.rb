class AddSettlementFieldsToActivityLogs < ActiveRecord::Migration[7.2]
  def change
    add_reference :activity_logs, :to_user, foreign_key: { to_table: :users }, null: true
    add_column :activity_logs, :amount, :decimal, precision: 12, scale: 2, null: true
  end
end
