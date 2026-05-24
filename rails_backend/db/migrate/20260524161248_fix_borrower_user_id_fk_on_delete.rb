class FixBorrowerUserIdFkOnDelete < ActiveRecord::Migration[7.2]
  def up
    remove_foreign_key :loans, column: :borrower_user_id
    add_foreign_key :loans, :users, column: :borrower_user_id, on_delete: :nullify
  end

  def down
    remove_foreign_key :loans, column: :borrower_user_id
    add_foreign_key :loans, :users, column: :borrower_user_id
  end
end
