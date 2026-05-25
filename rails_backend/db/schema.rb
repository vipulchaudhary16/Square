# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_05_25_125330) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activity_logs", force: :cascade do |t|
    t.string "loggable_type", null: false
    t.bigint "loggable_id", null: false
    t.bigint "user_id", null: false
    t.string "action", null: false
    t.text "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loggable_type", "loggable_id"], name: "index_activity_logs_on_loggable"
    t.index ["loggable_type", "loggable_id"], name: "index_activity_logs_on_loggable_type_and_loggable_id"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "month", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id", null: false
    t.index ["category_id"], name: "index_budgets_on_category_id"
    t.index ["user_id", "category_id", "month"], name: "index_budgets_on_user_id_and_category_id_and_month", unique: true
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "applies_to", default: [], array: true
    t.boolean "is_standard", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "user_id, lower((name)::text)", name: "index_categories_on_user_id_and_lower_name", unique: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.bigint "user_id", null: false
    t.text "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "owner_user_id", null: false
    t.bigint "linked_user_id"
    t.string "name", null: false
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linked_user_id"], name: "index_contacts_on_linked_user_id"
    t.index ["owner_user_id"], name: "index_contacts_on_owner_user_id"
  end

  create_table "expense_participants", force: :cascade do |t|
    t.bigint "expense_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id", "user_id"], name: "index_expense_participants_on_expense_id_and_user_id", unique: true
    t.index ["expense_id"], name: "index_expense_participants_on_expense_id"
    t.index ["user_id"], name: "index_expense_participants_on_user_id"
  end

  create_table "expense_splits", force: :cascade do |t|
    t.bigint "expense_id", null: false
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expense_id", "user_id"], name: "index_expense_splits_on_expense_id_and_user_id", unique: true
    t.index ["expense_id"], name: "index_expense_splits_on_expense_id"
    t.index ["user_id"], name: "index_expense_splits_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.string "description", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "date", null: false
    t.bigint "payer_id", null: false
    t.bigint "group_id"
    t.string "split_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id", null: false
    t.index ["category_id"], name: "index_expenses_on_category_id"
    t.index ["date"], name: "index_expenses_on_date"
    t.index ["group_id"], name: "index_expenses_on_group_id"
    t.index ["payer_id"], name: "index_expenses_on_payer_id"
  end

  create_table "feature_flag_registries", force: :cascade do |t|
    t.string "key", null: false
    t.text "description"
    t.string "category"
    t.boolean "user_toggleable", default: false, null: false
    t.boolean "default_value", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_feature_flag_registries_on_key", unique: true
  end

  create_table "group_invites", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.string "email", null: false
    t.string "token", null: false
    t.string "status", default: "pending", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_invites_on_group_id"
    t.index ["token"], name: "index_group_invites_on_token", unique: true
  end

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "user_id"], name: "index_group_memberships_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", default: ""
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_groups_on_created_by_id"
  end

  create_table "incomes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "source", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "date", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id", null: false
    t.index ["category_id"], name: "index_incomes_on_category_id"
    t.index ["user_id", "date"], name: "index_incomes_on_user_id_and_date"
    t.index ["user_id"], name: "index_incomes_on_user_id"
  end

  create_table "investments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "investment_type", null: false
    t.decimal "amount_invested", precision: 12, scale: 2, null: false
    t.decimal "current_value", precision: 12, scale: 2, null: false
    t.datetime "date", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id"
    t.index ["category_id"], name: "index_investments_on_category_id"
    t.index ["user_id", "date"], name: "index_investments_on_user_id_and_date"
    t.index ["user_id"], name: "index_investments_on_user_id"
  end

  create_table "loan_payments", force: :cascade do |t|
    t.bigint "loan_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "paid_at", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_loan_payments_on_loan_id"
  end

  create_table "loan_reminders", force: :cascade do |t|
    t.bigint "loan_id", null: false
    t.bigint "set_by_user_id", null: false
    t.datetime "remind_at", null: false
    t.boolean "nudge_borrower", default: false, null: false
    t.boolean "via_push", default: true, null: false
    t.boolean "via_sms", default: false, null: false
    t.boolean "via_email", default: true, null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_id"], name: "index_loan_reminders_on_loan_id"
    t.index ["set_by_user_id"], name: "index_loan_reminders_on_set_by_user_id"
  end

  create_table "loans", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "date", null: false
    t.datetime "due_date"
    t.string "status", default: "PENDING", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id"
    t.bigint "lender_user_id", null: false
    t.bigint "borrower_user_id"
    t.bigint "contact_id", null: false
    t.string "confirmation_status", default: "pending", null: false
    t.datetime "confirmed_at"
    t.string "interest_mode", default: "none", null: false
    t.decimal "interest_rate", precision: 8, scale: 6
    t.string "interest_period"
    t.string "interest_basis"
    t.index ["borrower_user_id"], name: "index_loans_on_borrower_user_id"
    t.index ["category_id"], name: "index_loans_on_category_id"
    t.index ["contact_id"], name: "index_loans_on_contact_id"
    t.index ["lender_user_id"], name: "index_loans_on_lender_user_id"
  end

  create_table "user_feature_flags", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "feature_flag_registry_id", null: false
    t.boolean "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_flag_registry_id"], name: "index_user_feature_flags_on_feature_flag_registry_id"
    t.index ["user_id", "feature_flag_registry_id"], name: "idx_on_user_id_feature_flag_registry_id_b0ae03ba17", unique: true
    t.index ["user_id"], name: "index_user_feature_flags_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", default: "", null: false
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "otp"
    t.datetime "otp_expiry"
    t.string "reset_token"
    t.datetime "reset_token_expiry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mobile_number"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_token"], name: "index_users_on_reset_token"
    t.index ["username"], name: "index_users_on_username"
  end

  add_foreign_key "activity_logs", "users"
  add_foreign_key "budgets", "categories"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "comments", "users"
  add_foreign_key "contacts", "users", column: "linked_user_id"
  add_foreign_key "contacts", "users", column: "owner_user_id"
  add_foreign_key "expense_participants", "expenses"
  add_foreign_key "expense_participants", "users"
  add_foreign_key "expense_splits", "expenses"
  add_foreign_key "expense_splits", "users"
  add_foreign_key "expenses", "categories"
  add_foreign_key "expenses", "groups"
  add_foreign_key "expenses", "users", column: "payer_id"
  add_foreign_key "group_invites", "groups"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "groups", "users", column: "created_by_id"
  add_foreign_key "incomes", "categories"
  add_foreign_key "incomes", "users"
  add_foreign_key "investments", "categories"
  add_foreign_key "investments", "users"
  add_foreign_key "loan_payments", "loans"
  add_foreign_key "loan_reminders", "loans"
  add_foreign_key "loan_reminders", "users", column: "set_by_user_id"
  add_foreign_key "loans", "categories"
  add_foreign_key "loans", "contacts"
  add_foreign_key "loans", "users", column: "borrower_user_id", on_delete: :nullify
  add_foreign_key "loans", "users", column: "lender_user_id"
  add_foreign_key "user_feature_flags", "feature_flag_registries"
  add_foreign_key "user_feature_flags", "users"
end
