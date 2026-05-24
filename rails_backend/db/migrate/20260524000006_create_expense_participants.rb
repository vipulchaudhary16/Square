class CreateExpenseParticipants < ActiveRecord::Migration[7.2]
  def change
    create_table :expense_participants do |t|
      t.references :expense, null: false, foreign_key: true
      t.references :user,    null: false, foreign_key: true
      t.timestamps
    end
    add_index :expense_participants, [:expense_id, :user_id], unique: true
  end
end
