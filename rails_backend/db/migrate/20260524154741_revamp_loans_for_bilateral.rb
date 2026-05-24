class RevampLoansForBilateral < ActiveRecord::Migration[7.2]
  def up
    # Step 1: add new columns (nullable for now so data migration can run)
    add_column :loans, :lender_user_id, :bigint
    add_column :loans, :borrower_user_id, :bigint
    add_column :loans, :contact_id, :bigint
    add_column :loans, :confirmation_status, :string, default: "pending", null: false
    add_column :loans, :confirmed_at, :datetime
    add_column :loans, :interest_mode, :string, default: "none", null: false
    add_column :loans, :interest_rate, :decimal, precision: 8, scale: 6
    add_column :loans, :interest_period, :string
    add_column :loans, :interest_basis, :string

    # Step 2: copy user_id → lender_user_id
    execute "UPDATE loans SET lender_user_id = user_id"

    # Step 3: create one contact per distinct (user_id, counterparty_name) pair
    # ON CONFLICT DO NOTHING is safe here even without a unique constraint on contacts —
    # it simply means "ignore any unique violation" and is valid PostgreSQL syntax.
    # Since we SELECT DISTINCT, we produce at most one row per (user_id, counterparty_name) pair.
    execute <<~SQL
      INSERT INTO contacts (owner_user_id, name, created_at, updated_at)
      SELECT DISTINCT user_id, counterparty_name, NOW(), NOW()
      FROM loans
      WHERE counterparty_name IS NOT NULL
      ON CONFLICT DO NOTHING
    SQL

    # Step 4: link each loan to its newly created contact
    execute <<~SQL
      UPDATE loans l
      SET contact_id = (
        SELECT c.id
        FROM contacts c
        WHERE c.owner_user_id = l.user_id
          AND c.name = l.counterparty_name
        LIMIT 1
      )
    SQL

    # Step 5: grandfather existing loans as confirmed (both sides agreed offline)
    execute "UPDATE loans SET confirmation_status = 'confirmed', confirmed_at = created_at"

    # Step 6: now enforce NOT NULL on required new columns
    # lender_user_id is always populated (copied from user_id in step 2)
    change_column_null :loans, :lender_user_id, false
    # contact_id: only enforce NOT NULL if all loans have counterparty_name set.
    # Since counterparty_name was null: false, contact_id should be set for all rows.
    # If any loan still has NULL contact_id (e.g. edge case), skip the constraint.
    null_contact_count = execute("SELECT COUNT(*) FROM loans WHERE contact_id IS NULL").first["count"].to_i
    if null_contact_count == 0
      change_column_null :loans, :contact_id, false
    else
      Rails.logger.warn "RevampLoansForBilateral: #{null_contact_count} loans have NULL contact_id — skipping NOT NULL constraint on contact_id"
    end

    # Step 7: add indices and foreign keys
    add_index :loans, :lender_user_id
    add_index :loans, :borrower_user_id
    add_index :loans, :contact_id
    add_foreign_key :loans, :users, column: :lender_user_id
    add_foreign_key :loans, :users, column: :borrower_user_id
    add_foreign_key :loans, :contacts, column: :contact_id

    # Step 8: drop old columns and their indices
    remove_index :loans, name: "index_loans_on_user_id"
    remove_index :loans, name: "index_loans_on_user_id_and_status"
    remove_column :loans, :user_id
    remove_column :loans, :counterparty_name
    remove_column :loans, :loan_type
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
