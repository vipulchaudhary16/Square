class CreateLoanReminders < ActiveRecord::Migration[7.2]
  def change
    create_table :loan_reminders do |t|
      t.references :loan,         null: false, foreign_key: true
      t.references :set_by_user,  null: false, foreign_key: { to_table: :users }
      t.datetime   :remind_at,    null: false
      t.boolean    :nudge_borrower, default: false, null: false
      t.boolean    :via_push,       default: true,  null: false
      t.boolean    :via_sms,        default: false, null: false
      t.boolean    :via_email,      default: true,  null: false
      t.datetime   :sent_at
      t.timestamps
    end
  end
end
