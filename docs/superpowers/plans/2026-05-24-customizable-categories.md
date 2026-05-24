# Customizable Categories Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace hardcoded category strings with a per-user `categories` table, add full CRUD API, and wire dynamic category dropdowns into all expense/income/budget forms on both web and Flutter.

**Architecture:** A new `categories` table is owned per-user and seeded with standard categories (Food, Transport, etc.) on signup. `expenses`, `incomes`, and `budgets` gain a `category_id` FK replacing the `category` string column. A new `CategoriesController` handles CRUD with guard rails (standard categories are undeletable/unrenameable; deleting a custom category reassigns its records to "Other").

**Tech Stack:** Rails 7.2 (PostgreSQL, ActiveRecord), React + TypeScript (Axios, react-router-dom), Flutter (Riverpod, Dio, go_router)

---

## File Map

**New files — Rails**
- `rails_backend/app/models/category.rb`
- `rails_backend/app/services/category_seeder.rb`
- `rails_backend/app/controllers/api/v1/categories_controller.rb`
- `rails_backend/db/migrate/*_create_categories.rb`
- `rails_backend/db/migrate/*_add_category_id_to_tables.rb`
- `rails_backend/db/migrate/*_backfill_category_ids.rb`
- `rails_backend/db/migrate/*_finalize_category_migration.rb`

**Modified files — Rails**
- `rails_backend/app/models/user.rb`
- `rails_backend/app/models/expense.rb`
- `rails_backend/app/models/income.rb`
- `rails_backend/app/models/budget.rb`
- `rails_backend/app/controllers/api/v1/expenses_controller.rb`
- `rails_backend/app/controllers/api/v1/incomes_controller.rb`
- `rails_backend/app/controllers/api/v1/budgets_controller.rb`
- `rails_backend/app/controllers/api/v1/auth_controller.rb`
- `rails_backend/engines/dashboard/app/controllers/dashboard/dashboard_controller.rb`
- `rails_backend/config/routes.rb`

**New files — Frontend**
- `frontend/src/api/categories.ts`
- `frontend/src/modules/settings/pages/CategoriesPage.tsx`

**Modified files — Frontend**
- `frontend/src/App.tsx`
- `frontend/src/api/expenses.ts`
- `frontend/src/modules/common/components/Topbar.tsx`
- `frontend/src/modules/expense/components/AddExpenseForm.tsx`
- `frontend/src/modules/expense/components/BudgetForm.tsx`
- `frontend/src/modules/income/components/IncomeForm.tsx`
- `frontend/src/modules/income/pages/IncomeDetailsPage.tsx`

**New files — Flutter**
- `square_app/lib/features/categories/data/category_model.dart`
- `square_app/lib/features/categories/data/categories_repository.dart`
- `square_app/lib/features/categories/presentation/categories_provider.dart`
- `square_app/lib/features/categories/presentation/categories_settings_screen.dart`

**Modified files — Flutter**
- `square_app/lib/core/router.dart`
- `square_app/lib/features/profile/presentation/profile_screen.dart`
- `square_app/lib/features/expense/data/expense_model.dart`
- `square_app/lib/features/expense/presentation/screens/add_edit_expense_screen.dart`
- `square_app/lib/features/transactions/data/income_model.dart`
- `square_app/lib/features/transactions/presentation/screens/add_edit_income_screen.dart`

---

## Task 1: Create categories table migration + model

**Files:**
- Create: `rails_backend/db/migrate/*_create_categories.rb`
- Create: `rails_backend/app/models/category.rb`

- [ ] **Step 1: Generate the migration**

```bash
cd rails_backend
rails generate migration CreateCategories
```

- [ ] **Step 2: Fill in the migration file** (replace the generated body)

```ruby
class CreateCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string     :name,        null: false
      t.text       :applies_to,  array: true, default: []
      t.boolean    :is_standard, null: false, default: false
      t.timestamps
    end

    add_index :categories, [:user_id, :name], unique: true
  end
end
```

- [ ] **Step 3: Run the migration**

```bash
rails db:migrate
```

Expected: `CreateCategories: migrated`

- [ ] **Step 4: Create the model**

Create `rails_backend/app/models/category.rb`:

```ruby
class Category < ApplicationRecord
  STANDARD_NAMES = %w[Food Transport Utilities Entertainment Shopping Health Travel General Other].freeze

  belongs_to :user

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :applies_to, presence: true
  validate :applies_to_must_be_valid

  private

  def applies_to_must_be_valid
    valid_types = %w[expense income budget]
    unless applies_to.is_a?(Array) && applies_to.any? && applies_to.all? { |t| valid_types.include?(t) }
      errors.add(:applies_to, "must include at least one of: expense, income, budget")
    end
  end
end
```

- [ ] **Step 5: Verify in Rails console**

```bash
rails console
```

```ruby
# Should be valid
cat = Category.new(user: User.first, name: "Test", applies_to: ["expense"])
cat.valid? # => true

# Should be invalid — empty applies_to
cat2 = Category.new(user: User.first, name: "Test2", applies_to: [])
cat2.valid? # => false
cat2.errors[:applies_to] # => ["must include at least one of: expense, income, budget"]
exit
```

- [ ] **Step 6: Commit**

```bash
cd rails_backend
git add db/migrate/*_create_categories.rb app/models/category.rb
git commit -m "feat: add categories table and model"
```

---

## Task 2: CategorySeeder service

**Files:**
- Create: `rails_backend/app/services/category_seeder.rb`

- [ ] **Step 1: Create the seeder service**

Create `rails_backend/app/services/category_seeder.rb`:

```ruby
class CategorySeeder
  STANDARD = [
    { name: "Food",          applies_to: %w[expense income budget] },
    { name: "Transport",     applies_to: %w[expense income budget] },
    { name: "Utilities",     applies_to: %w[expense income budget] },
    { name: "Entertainment", applies_to: %w[expense income budget] },
    { name: "Shopping",      applies_to: %w[expense income budget] },
    { name: "Health",        applies_to: %w[expense income budget] },
    { name: "Travel",        applies_to: %w[expense income budget] },
    { name: "General",       applies_to: %w[expense income budget] },
    { name: "Other",         applies_to: %w[expense income budget] },
  ].freeze

  def self.seed(user)
    STANDARD.each do |attrs|
      user.categories.find_or_create_by!(name: attrs[:name]) do |cat|
        cat.applies_to  = attrs[:applies_to]
        cat.is_standard = true
      end
    end
  end
end
```

- [ ] **Step 2: Verify in Rails console**

```bash
rails console
```

```ruby
user = User.first
CategorySeeder.seed(user)
user.categories.count  # => 9
user.categories.pluck(:name)
# => ["Food", "Transport", "Utilities", "Entertainment", "Shopping", "Health", "Travel", "General", "Other"]
exit
```

- [ ] **Step 3: Commit**

```bash
git add app/services/category_seeder.rb
git commit -m "feat: add CategorySeeder service with 9 standard categories"
```

---

## Task 3: Seed on signup + seed all existing users

**Files:**
- Modify: `rails_backend/app/models/user.rb`
- Modify: `rails_backend/app/controllers/api/v1/auth_controller.rb`
- Create: `rails_backend/db/migrate/*_seed_categories_for_existing_users.rb`

- [ ] **Step 1: Add has_many :categories to User model**

In `rails_backend/app/models/user.rb`, add inside the class body after the existing `has_many` lines:

```ruby
has_many :categories, dependent: :destroy
```

- [ ] **Step 2: Seed categories after user signup**

In `rails_backend/app/controllers/api/v1/auth_controller.rb`, update the `signup` action to seed categories after save:

```ruby
def signup
  user = User.new(
    email:      params[:email],
    first_name: params[:first_name] || "",
    last_name:  params[:last_name]  || "",
    username:   params[:username],
    password:   params[:password]
  )
  if user.save
    CategorySeeder.seed(user)
    token = JwtService.encode({ user_id: user.id.to_s })
    render json: { token: token, user: user_json(user) }, status: :created
  else
    render json: { error: user.errors.full_messages.first }, status: :bad_request
  end
end
```

- [ ] **Step 3: Generate migration to seed existing users**

```bash
rails generate migration SeedCategoriesForExistingUsers
```

Fill in the generated file:

```ruby
class SeedCategoriesForExistingUsers < ActiveRecord::Migration[7.2]
  def up
    User.find_each { |user| CategorySeeder.seed(user) }
  end

  def down
    Category.where(is_standard: true).delete_all
  end
end
```

- [ ] **Step 4: Run migration**

```bash
rails db:migrate
```

- [ ] **Step 5: Verify**

```bash
rails console
```

```ruby
User.all.all? { |u| u.categories.count == 9 }  # => true
exit
```

- [ ] **Step 6: Commit**

```bash
git add app/models/user.rb app/controllers/api/v1/auth_controller.rb db/migrate/*_seed_categories_for_existing_users.rb
git commit -m "feat: seed standard categories on signup and for existing users"
```

---

## Task 4: Add category_id FK to expenses, incomes, budgets (nullable)

**Files:**
- Create: `rails_backend/db/migrate/*_add_category_id_to_tables.rb`

- [ ] **Step 1: Generate migration**

```bash
rails generate migration AddCategoryIdToTables
```

Fill in the generated file:

```ruby
class AddCategoryIdToTables < ActiveRecord::Migration[7.2]
  def change
    add_reference :expenses, :category, foreign_key: true, null: true
    add_reference :incomes,  :category, foreign_key: true, null: true
    add_reference :budgets,  :category, foreign_key: true, null: true
  end
end
```

- [ ] **Step 2: Run migration**

```bash
rails db:migrate
```

Expected: `AddCategoryIdToTables: migrated`

- [ ] **Step 3: Commit**

```bash
git add db/migrate/*_add_category_id_to_tables.rb
git commit -m "feat: add nullable category_id FK to expenses, incomes, budgets"
```

---

## Task 5: Backfill category_id from existing category string values

**Files:**
- Create: `rails_backend/db/migrate/*_backfill_category_ids.rb`

- [ ] **Step 1: Generate migration**

```bash
rails generate migration BackfillCategoryIds
```

Fill in the generated file:

```ruby
class BackfillCategoryIds < ActiveRecord::Migration[7.2]
  def up
    # Expenses — payer owns the category
    Expense.where(category_id: nil).find_each do |expense|
      owner = User.find_by(id: expense.payer_id)
      next unless owner
      cat = owner.categories.find_by("lower(name) = ?", expense.category.downcase) ||
            owner.categories.find_by(name: "General")
      expense.update_column(:category_id, cat&.id)
    end

    # Incomes
    Income.where(category_id: nil).find_each do |income|
      cat = income.user.categories.find_by("lower(name) = ?", income.category.to_s.downcase) ||
            income.user.categories.find_by(name: "General")
      income.update_column(:category_id, cat&.id)
    end

    # Budgets
    Budget.where(category_id: nil).find_each do |budget|
      if budget.category == "OVERALL"
        # Keep as-is; OVERALL is a special budget type, map to General
        cat = budget.user.categories.find_by(name: "General")
      else
        cat = budget.user.categories.find_by("lower(name) = ?", budget.category.to_s.downcase) ||
              budget.user.categories.find_by(name: "General")
      end
      budget.update_column(:category_id, cat&.id)
    end
  end

  def down
    Expense.update_all(category_id: nil)
    Income.update_all(category_id: nil)
    Budget.update_all(category_id: nil)
  end
end
```

- [ ] **Step 2: Run migration**

```bash
rails db:migrate
```

- [ ] **Step 3: Verify**

```bash
rails console
```

```ruby
Expense.where(category_id: nil).count  # => 0
Income.where(category_id: nil).count   # => 0
Budget.where(category_id: nil).count   # => 0
exit
```

- [ ] **Step 4: Commit**

```bash
git add db/migrate/*_backfill_category_ids.rb
git commit -m "feat: backfill category_id on expenses, incomes, budgets from category string"
```

---

## Task 6: Finalize — make category_id not null, drop category string columns

**Files:**
- Create: `rails_backend/db/migrate/*_finalize_category_migration.rb`

- [ ] **Step 1: Generate migration**

```bash
rails generate migration FinalizeCategoryMigration
```

Fill in the generated file:

```ruby
class FinalizeCategoryMigration < ActiveRecord::Migration[7.2]
  def up
    # Make category_id not null
    change_column_null :expenses, :category_id, false
    change_column_null :incomes,  :category_id, false
    change_column_null :budgets,  :category_id, false

    # Drop old string columns
    remove_column :expenses, :category
    remove_column :incomes,  :category
    remove_column :budgets,  :category

    # Replace budget unique index (category string → category_id)
    remove_index :budgets, name: "index_budgets_on_user_id_and_category_and_month", if_exists: true
    add_index :budgets, [:user_id, :category_id, :month], unique: true, name: "index_budgets_on_user_id_and_category_id_and_month"
  end

  def down
    add_column :expenses, :category, :string, default: "", null: false
    add_column :incomes,  :category, :string, default: "", null: false
    add_column :budgets,  :category, :string, default: "", null: false
    change_column_null :expenses, :category_id, true
    change_column_null :incomes,  :category_id, true
    change_column_null :budgets,  :category_id, true
  end
end
```

- [ ] **Step 2: Run migration**

```bash
rails db:migrate
```

- [ ] **Step 3: Verify schema**

```bash
rails console
```

```ruby
Expense.column_names.include?("category")     # => false
Expense.column_names.include?("category_id")  # => true
exit
```

- [ ] **Step 4: Commit**

```bash
git add db/migrate/*_finalize_category_migration.rb
git commit -m "feat: make category_id not null, drop legacy category string columns"
```

---

## Task 7: Update Expense, Income, Budget models

**Files:**
- Modify: `rails_backend/app/models/expense.rb`
- Modify: `rails_backend/app/models/income.rb`
- Modify: `rails_backend/app/models/budget.rb`

- [ ] **Step 1: Update Expense model**

Replace the full contents of `rails_backend/app/models/expense.rb`:

```ruby
class Expense < ApplicationRecord
  SPLIT_TYPES = %w[EQUAL EXACT PERCENT].freeze

  belongs_to :payer, class_name: "User"
  belongs_to :group, optional: true
  belongs_to :category
  has_many :expense_participants, dependent: :destroy
  has_many :participants, through: :expense_participants, source: :user
  has_many :expense_splits, dependent: :destroy
  has_many :activity_logs, as: :loggable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  validates :description, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :split_type, inclusion: { in: SPLIT_TYPES }, allow_nil: true

  scope :accessible_to, ->(user) {
    joins("LEFT JOIN expense_participants ep ON ep.expense_id = expenses.id")
      .where("expenses.payer_id = :uid OR ep.user_id = :uid", uid: user.id)
      .distinct
  }

  scope :with_filters, ->(params) {
    s = all
    s = s.where(group_id: nil) if params[:personal_only] == "true"
    s = s.where(category_id: params[:category_id]) if params[:category_id].present?
    s = s.where("date >= ?", params[:start_date]) if params[:start_date].present?
    s = s.where("date <= ?", params[:end_date]) if params[:end_date].present?
    s = s.where("description ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:search])}%") if params[:search].present?
    s
  }

  scope :with_sort, ->(params) {
    col   = %w[date amount].include?(params[:sort_by]) ? params[:sort_by] : "date"
    order = params[:sort_order] == "asc" ? :asc : :desc
    reorder(col => order)
  }
end
```

- [ ] **Step 2: Update Income model**

Replace the full contents of `rails_backend/app/models/income.rb`:

```ruby
class Income < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :activity_logs, as: :loggable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  validates :source, :amount, :date, presence: true
  validates :amount, numericality: { greater_than: 0 }
end
```

- [ ] **Step 3: Update Budget model**

Replace the full contents of `rails_backend/app/models/budget.rb`:

```ruby
class Budget < ApplicationRecord
  belongs_to :user
  belongs_to :category
  validates :category_id, :amount, :month, presence: true
  validates :month, format: { with: /\A\d{4}-\d{2}\z/, message: "must be YYYY-MM" }
  validates :category_id, uniqueness: { scope: [:user_id, :month] }
  validates :amount, numericality: { greater_than: 0 }
end
```

- [ ] **Step 4: Verify in console**

```bash
rails console
```

```ruby
e = Expense.includes(:category).first
e.category.name  # => "Food" (or whatever was backfilled)
exit
```

- [ ] **Step 5: Commit**

```bash
git add app/models/expense.rb app/models/income.rb app/models/budget.rb
git commit -m "feat: add belongs_to :category to Expense, Income, Budget models"
```

---

## Task 8: CategoriesController + routes

**Files:**
- Create: `rails_backend/app/controllers/api/v1/categories_controller.rb`
- Modify: `rails_backend/config/routes.rb`

- [ ] **Step 1: Create CategoriesController**

Create `rails_backend/app/controllers/api/v1/categories_controller.rb`:

```ruby
module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :set_category, only: [:update, :destroy]

      def index
        categories = current_user.categories
        categories = categories.where("? = ANY(applies_to)", params[:applies_to]) if params[:applies_to].present?
        render json: categories.order(:name).map { |c| serialize(c) }
      end

      def create
        category = current_user.categories.create!(
          name:       params[:name],
          applies_to: Array(params[:applies_to]),
          is_standard: false
        )
        render json: serialize(category), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        if @category.is_standard
          render json: { error: "Standard categories cannot be renamed" }, status: :unprocessable_entity and return
        end
        if @category.update(name: params[:name], applies_to: Array(params[:applies_to]))
          render json: serialize(@category)
        else
          render json: { error: @category.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        if @category.is_standard
          render json: { error: "Standard categories cannot be deleted" }, status: :unprocessable_entity and return
        end

        other = current_user.categories.find_by!(name: "Other")
        Expense.where(payer_id: current_user.id, category_id: @category.id).update_all(category_id: other.id)
        Income.where(user_id: current_user.id, category_id: @category.id).update_all(category_id: other.id)
        Budget.where(user_id: current_user.id, category_id: @category.id).update_all(category_id: other.id)

        @category.destroy!
        render json: { message: "Category deleted. Records moved to 'Other'." }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Category not found" }, status: :not_found
      end

      private

      def set_category
        @category = current_user.categories.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Category not found" }, status: :not_found
      end

      def serialize(c)
        { id: c.id.to_s, name: c.name, applies_to: c.applies_to, is_standard: c.is_standard }
      end
    end
  end
end
```

- [ ] **Step 2: Add routes**

In `rails_backend/config/routes.rb`, add inside the `scope module: "api/v1"` block, after the budgets resources line:

```ruby
resources :categories, only: [:index, :create, :update, :destroy]
```

- [ ] **Step 3: Verify routes**

```bash
rails routes | grep categories
```

Expected output includes:
```
GET    /api/categories
POST   /api/categories
PATCH  /api/categories/:id
DELETE /api/categories/:id
```

- [ ] **Step 4: Manual smoke test**

Start the Rails server (`rails s`) and run:

```bash
# Login first to get a token
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"your@email.com","password":"yourpassword"}' | jq -r '.token')

# List categories
curl -s http://localhost:8080/api/categories \
  -H "Authorization: Bearer $TOKEN" | jq '.'
# => array of 9 standard categories

# Create custom category
curl -s -X POST http://localhost:8080/api/categories \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Freelance","applies_to":["income"]}' | jq '.'
# => { "id": "...", "name": "Freelance", "applies_to": ["income"], "is_standard": false }

# Try deleting a standard category
curl -s -X DELETE http://localhost:8080/api/categories/1 \
  -H "Authorization: Bearer $TOKEN" | jq '.'
# => { "error": "Standard categories cannot be deleted" }
```

- [ ] **Step 5: Commit**

```bash
git add app/controllers/api/v1/categories_controller.rb config/routes.rb
git commit -m "feat: add CategoriesController with CRUD and standard-category guards"
```

---

## Task 9: Update ExpensesController

**Files:**
- Modify: `rails_backend/app/controllers/api/v1/expenses_controller.rb`

- [ ] **Step 1: Update create, update, and serialize_list**

Replace the full contents of `rails_backend/app/controllers/api/v1/expenses_controller.rb`:

```ruby
module Api
  module V1
    class ExpensesController < ApplicationController
      before_action :set_expense, only: [:show, :update, :destroy, :comments]

      def index
        expenses = Expense
          .accessible_to(current_user)
          .with_filters(params)
          .with_sort(params)
          .includes(:payer, :group, :category, :expense_splits, :expense_participants)

        if params[:limit].present?
          page  = (params[:page] || 1).to_i
          limit = params[:limit].to_i
          total = expenses.count
          data  = expenses.offset((page - 1) * limit).limit(limit)
          render json: { data: serialize_list(data), total: total, page: page, limit: limit }
        else
          render json: serialize_list(expenses)
        end
      end

      def show
        logs     = @expense.activity_logs.includes(:user).order(created_at: :desc)
        comments = @expense.comments.includes(:user).order(created_at: :asc)
        user_ids = [
          @expense.payer_id,
          *@expense.expense_splits.map(&:user_id),
          *@expense.expense_participants.map(&:user_id),
          *logs.map(&:user_id),
          *comments.map(&:user_id)
        ]
        render json: {
          expense:  serialize_list([@expense]).first,
          logs:     logs.map { |l| { id: l.id.to_s, user_id: l.user_id.to_s, action: l.action, details: l.details, created_at: l.created_at.iso8601 } },
          comments: comments.map { |c| { id: c.id.to_s, user_id: c.user_id.to_s, text: c.text, created_at: c.created_at.iso8601 } },
          users:    build_user_map(user_ids)
        }
      end

      def create
        category = current_user.categories.find_by(id: params[:category_id]) ||
                   current_user.categories.find_by(name: "General")

        participant_ids = params[:participants] || [current_user.id.to_s]
        raw_splits      = params[:splits]&.to_unsafe_h || {}
        splits_calculated = ExpenseSplitCalculator.calculate(
          params[:amount].to_f, params[:split_type], participant_ids, raw_splits
        )

        expense = Expense.new(
          description: params[:description],
          amount:      params[:amount],
          category_id: category.id,
          date:        params[:date] || Time.current,
          payer_id:    current_user.id,
          group_id:    params[:group_id],
          split_type:  params[:split_type] || "EQUAL"
        )

        Expense.transaction do
          expense.save!
          participant_ids.each { |uid| ExpenseParticipant.create!(expense: expense, user_id: uid) }
          splits_calculated.each { |uid, amt| ExpenseSplit.create!(expense: expense, user_id: uid, amount: amt) }
          log_activity(loggable: expense, action: "CREATE", details: "Expense created: #{expense.description}")
        end

        render json: { message: "Expense created successfully", expense: { id: expense.id.to_s } }, status: :created
      rescue ArgumentError => e
        render json: { error: e.message }, status: :bad_request
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        changes = []

        if params[:category_id].present?
          new_cat = current_user.categories.find_by(id: params[:category_id])
          if new_cat && new_cat.id != @expense.category_id
            changes << "category: #{@expense.category.name} → #{new_cat.name}"
            @expense.category_id = new_cat.id
          end
        end

        [:description, :amount, :date, :split_type].each do |field|
          next unless params[field].present?
          old_val = @expense.send(field)
          new_val = params[field]
          if old_val.to_s != new_val.to_s
            changes << "#{field}: #{old_val} → #{new_val}"
            @expense.assign_attributes(field => new_val)
          end
        end

        if @expense.save
          log_activity(loggable: @expense, action: "UPDATE", details: changes.join(", ")) if changes.any?
          render json: { message: "Expense updated successfully" }
        else
          render json: { error: @expense.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @expense.destroy!
        render json: { message: "Expense deleted successfully" }
      end

      def comments
        comment = Comment.create!(commentable: @expense, user: current_user, text: params[:text])
        log_activity(loggable: @expense, action: "COMMENT", details: params[:text])
        render json: { id: comment.id.to_s, user_id: comment.user_id.to_s, text: comment.text, created_at: comment.created_at.iso8601 }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_expense
        @expense = Expense.accessible_to(current_user)
                          .includes(:category, :expense_splits, :expense_participants)
                          .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Expense not found" }, status: :not_found
      end

      def serialize_list(expenses)
        expenses.map do |e|
          {
            id:            e.id.to_s,
            description:   e.description,
            amount:        e.amount.to_f,
            category_id:   e.category_id.to_s,
            category_name: e.category&.name || "",
            date:          e.date.iso8601,
            payer_id:      e.payer_id.to_s,
            payer_name:    e.payer.display_name,
            group_id:      e.group_id&.to_s,
            group_name:    e.group&.name,
            split_type:    e.split_type,
            participants:  e.expense_participants.map { |p| p.user_id.to_s },
            splits:        e.expense_splits.each_with_object({}) { |s, h| h[s.user_id.to_s] = s.amount.to_f },
            created_at:    e.created_at.iso8601
          }
        end
      end
    end
  end
end
```

- [ ] **Step 2: Verify**

```bash
curl -s http://localhost:8080/api/expenses \
  -H "Authorization: Bearer $TOKEN" | jq '.[0] | {category_id, category_name}'
# => { "category_id": "1", "category_name": "Food" }
```

- [ ] **Step 3: Commit**

```bash
git add app/controllers/api/v1/expenses_controller.rb
git commit -m "feat: update ExpensesController to use category_id + category_name"
```

---

## Task 10: Update IncomesController

**Files:**
- Modify: `rails_backend/app/controllers/api/v1/incomes_controller.rb`

- [ ] **Step 1: Update create, income_params, and serialize**

In `rails_backend/app/controllers/api/v1/incomes_controller.rb`:

1. Replace `income_params` method:

```ruby
def income_params
  params.permit(:source, :amount, :category_id, :date, :description)
end
```

2. In `create`, resolve category before building the record. Replace the `create` action:

```ruby
def create
  category = current_user.categories.find_by(id: params[:category_id]) ||
             current_user.categories.find_by(name: "General")
  income = current_user.incomes.create!(
    income_params.except(:category_id).merge(category_id: category.id)
  )
  render json: serialize(income), status: :created
rescue ActiveRecord::RecordInvalid => e
  render json: { error: e.message }, status: :bad_request
end
```

3. Replace `serialize` method:

```ruby
def serialize(r)
  { id: r.id.to_s, user_id: r.user_id.to_s, source: r.source, amount: r.amount.to_f,
    category_id: r.category_id.to_s, category_name: r.category&.name || "",
    date: r.date.iso8601, description: r.description, created_at: r.created_at.iso8601 }
end
```

4. Update `index` to eager-load category:

```ruby
def index
  render json: current_user.incomes.includes(:category).order(date: :desc).map { |r| serialize(r) }
end
```

- [ ] **Step 2: Verify**

```bash
curl -s http://localhost:8080/api/incomes \
  -H "Authorization: Bearer $TOKEN" | jq '.[0] | {category_id, category_name}'
```

- [ ] **Step 3: Commit**

```bash
git add app/controllers/api/v1/incomes_controller.rb
git commit -m "feat: update IncomesController to use category_id + category_name"
```

---

## Task 11: Update BudgetsController

**Files:**
- Modify: `rails_backend/app/controllers/api/v1/budgets_controller.rb`

- [ ] **Step 1: Replace full file**

```ruby
module Api
  module V1
    class BudgetsController < ApplicationController
      before_action :set_budget, only: [:update, :destroy]

      def index
        budgets = current_user.budgets.includes(:category)
        budgets = budgets.where(month: params[:month]) if params[:month].present?
        render json: budgets.order("categories.name").joins(:category).map { |b| serialize(b) }
      end

      def create
        category = current_user.categories.find_by(id: params[:category_id]) ||
                   current_user.categories.find_by(name: "General")
        budget = current_user.budgets.create!(
          category_id: category.id,
          amount:      params[:amount],
          month:       params[:month]
        )
        render json: serialize(budget), status: :created
      rescue ActiveRecord::RecordInvalid => e
        if e.message.include?("already been taken")
          render json: { error: "Budget for this category and month already exists" }, status: :conflict
        else
          render json: { error: e.message }, status: :bad_request
        end
      end

      def update
        if @budget.update(amount: params[:amount])
          render json: { message: "Budget updated successfully" }
        else
          render json: { error: @budget.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @budget.destroy!
        render json: { message: "Budget deleted successfully" }
      end

      private

      def set_budget
        @budget = current_user.budgets.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Budget not found" }, status: :not_found
      end

      def serialize(b)
        { id: b.id.to_s, user_id: b.user_id.to_s,
          category_id: b.category_id.to_s, category_name: b.category&.name || "",
          amount: b.amount.to_f, month: b.month, created_at: b.created_at.iso8601 }
      end
    end
  end
end
```

- [ ] **Step 2: Verify**

```bash
curl -s "http://localhost:8080/api/budgets?month=2026-05" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

- [ ] **Step 3: Commit**

```bash
git add app/controllers/api/v1/budgets_controller.rb
git commit -m "feat: update BudgetsController to use category_id + category_name"
```

---

## Task 12: Update DashboardController

**Files:**
- Modify: `rails_backend/engines/dashboard/app/controllers/dashboard/dashboard_controller.rb`

- [ ] **Step 1: Update recent_expenses serialization**

In `rails_backend/engines/dashboard/app/controllers/dashboard/dashboard_controller.rb`, find the `recent_expenses.map` block and replace `category: e.category` with `category_name: e.category&.name || ""`.

The map block should read:

```ruby
recent_expenses: recent_expenses.map { |e|
  {
    id:            e.id.to_s,
    description:   e.description,
    amount:        e.amount.to_f,
    category_id:   e.category_id.to_s,
    category_name: e.category&.name || "",
    date:          e.date.iso8601,
    payer_id:      e.payer_id.to_s,
    payer_name:    e.payer.display_name,
    group_id:      e.group_id&.to_s,
    group_name:    e.group&.name,
    participants:  e.expense_participants.map { |p| p.user_id.to_s },
    splits:        {}
  }
},
```

Also update the `recent_expenses` query to eager-load category:

```ruby
recent_expenses = expense_model
  .where(id: user_expense_ids)
  .includes(:payer, :group, :category, :expense_participants)
  .order(date: :desc)
  .limit(5)
```

- [ ] **Step 2: Verify**

```bash
curl -s "http://localhost:8080/api/dashboard" \
  -H "Authorization: Bearer $TOKEN" | jq '.recent_expenses[0] | {category_id, category_name}'
```

- [ ] **Step 3: Commit**

```bash
git add engines/dashboard/app/controllers/dashboard/dashboard_controller.rb
git commit -m "feat: update DashboardController to use category_id + category_name"
```

---

## Task 13: Frontend — categories API + update interfaces

**Files:**
- Create: `frontend/src/api/categories.ts`
- Modify: `frontend/src/api/expenses.ts`

- [ ] **Step 1: Create categories API**

Create `frontend/src/api/categories.ts`:

```typescript
import api from './index';

export interface Category {
    id: string;
    name: string;
    applies_to: ('expense' | 'income' | 'budget')[];
    is_standard: boolean;
}

export const getCategories = async (appliesTo?: string): Promise<Category[]> => {
    const params = appliesTo ? `?applies_to=${appliesTo}` : '';
    const response = await api.get(`/categories${params}`);
    return response.data;
};

export const createCategory = async (data: {
    name: string;
    applies_to: string[];
}): Promise<Category> => {
    const response = await api.post('/categories', data);
    return response.data;
};

export const updateCategory = async (
    id: string,
    data: { name: string; applies_to: string[] },
): Promise<Category> => {
    const response = await api.patch(`/categories/${id}`, data);
    return response.data;
};

export const deleteCategory = async (id: string): Promise<void> => {
    await api.delete(`/categories/${id}`);
};
```

- [ ] **Step 2: Update Expense interface in expenses.ts**

In `frontend/src/api/expenses.ts`, replace the `Expense` interface:

```typescript
export interface Expense {
    id: string;
    description: string;
    amount: number;
    category_id: string;
    category_name: string;
    date: string;
    payer_id: string;
    group_id?: string;
    split_type?: string;
    participants?: string[];
    splits?: Record<string, number>;
    group_name?: string;
}
```

- [ ] **Step 3: Commit**

```bash
cd frontend
git add src/api/categories.ts src/api/expenses.ts
git commit -m "feat: add categories API and update Expense interface"
```

---

## Task 14: Frontend — CategoriesPage

**Files:**
- Create: `frontend/src/modules/settings/pages/CategoriesPage.tsx`

- [ ] **Step 1: Create the page**

```bash
mkdir -p frontend/src/modules/settings/pages
```

Create `frontend/src/modules/settings/pages/CategoriesPage.tsx`:

```typescript
import React, { useEffect, useState } from 'react';
import { Tag, Plus, Trash2, Lock, Pencil, X, Check } from 'lucide-react';
import {
    getCategories,
    createCategory,
    updateCategory,
    deleteCategory,
    Category,
} from '../../../api/categories';

const TYPE_LABELS: Record<string, string> = {
    expense: 'Expense',
    income: 'Income',
    budget: 'Budget',
};

export const CategoriesPage: React.FC = () => {
    const [categories, setCategories] = useState<Category[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [showForm, setShowForm] = useState(false);
    const [newName, setNewName] = useState('');
    const [newAppliesTo, setNewAppliesTo] = useState<string[]>(['expense', 'income', 'budget']);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [editName, setEditName] = useState('');
    const [editAppliesTo, setEditAppliesTo] = useState<string[]>([]);

    const load = async () => {
        try {
            const data = await getCategories();
            setCategories(data);
        } catch {
            setError('Failed to load categories');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { load(); }, []);

    const handleCreate = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!newName.trim() || newAppliesTo.length === 0) return;
        try {
            await createCategory({ name: newName.trim(), applies_to: newAppliesTo });
            setNewName('');
            setNewAppliesTo(['expense', 'income', 'budget']);
            setShowForm(false);
            load();
        } catch (err: any) {
            setError(err.response?.data?.error || 'Failed to create category');
        }
    };

    const handleDelete = async (cat: Category) => {
        if (!confirm(`Deleting "${cat.name}" will move all its records to "Other". Continue?`)) return;
        try {
            await deleteCategory(cat.id);
            load();
        } catch (err: any) {
            setError(err.response?.data?.error || 'Failed to delete category');
        }
    };

    const startEdit = (cat: Category) => {
        setEditingId(cat.id);
        setEditName(cat.name);
        setEditAppliesTo([...cat.applies_to]);
    };

    const handleUpdate = async (cat: Category) => {
        if (!editName.trim() || editAppliesTo.length === 0) return;
        try {
            await updateCategory(cat.id, { name: editName.trim(), applies_to: editAppliesTo });
            setEditingId(null);
            load();
        } catch (err: any) {
            setError(err.response?.data?.error || 'Failed to update category');
        }
    };

    const toggleType = (types: string[], type: string, setter: (v: string[]) => void) => {
        setter(types.includes(type) ? types.filter((t) => t !== type) : [...types, type]);
    };

    if (loading) return <div className="p-6">Loading...</div>;

    return (
        <div className="max-w-2xl mx-auto p-6">
            <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-2">
                    <Tag className="w-5 h-5 text-primary-600" />
                    <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Categories</h1>
                </div>
                <button
                    onClick={() => setShowForm(!showForm)}
                    className="flex items-center gap-2 bg-primary-600 hover:bg-primary-700 text-white px-4 py-2 rounded-xl text-sm font-medium transition-colors"
                >
                    <Plus className="w-4 h-4" />
                    Add Category
                </button>
            </div>

            {error && (
                <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 rounded-xl text-sm">
                    {error}
                </div>
            )}

            {showForm && (
                <form
                    onSubmit={handleCreate}
                    className="mb-6 p-4 bg-white dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm"
                >
                    <h2 className="text-sm font-semibold text-slate-700 dark:text-slate-300 mb-3">
                        New Category
                    </h2>
                    <input
                        type="text"
                        required
                        value={newName}
                        onChange={(e) => setNewName(e.target.value)}
                        placeholder="Category name"
                        className="w-full p-2 border rounded-lg mb-3 text-sm bg-white dark:bg-slate-700 border-slate-300 dark:border-slate-600 text-slate-900 dark:text-white"
                    />
                    <div className="flex gap-2 mb-3">
                        {['expense', 'income', 'budget'].map((type) => (
                            <button
                                key={type}
                                type="button"
                                onClick={() => toggleType(newAppliesTo, type, setNewAppliesTo)}
                                className={`px-3 py-1 rounded-full text-xs font-medium border transition-colors ${
                                    newAppliesTo.includes(type)
                                        ? 'bg-primary-100 dark:bg-primary-900/30 border-primary-400 text-primary-700 dark:text-primary-300'
                                        : 'bg-white dark:bg-slate-700 border-slate-300 dark:border-slate-600 text-slate-500'
                                }`}
                            >
                                {TYPE_LABELS[type]}
                            </button>
                        ))}
                    </div>
                    <div className="flex gap-2">
                        <button
                            type="submit"
                            className="flex-1 bg-primary-600 hover:bg-primary-700 text-white py-2 rounded-lg text-sm font-medium"
                        >
                            Create
                        </button>
                        <button
                            type="button"
                            onClick={() => setShowForm(false)}
                            className="px-4 py-2 text-sm text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg"
                        >
                            Cancel
                        </button>
                    </div>
                </form>
            )}

            <div className="space-y-2">
                {categories.map((cat) => (
                    <div
                        key={cat.id}
                        className="flex items-center gap-3 p-4 bg-white dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700"
                    >
                        {editingId === cat.id ? (
                            <div className="flex-1 flex flex-col gap-2">
                                <input
                                    type="text"
                                    value={editName}
                                    onChange={(e) => setEditName(e.target.value)}
                                    className="w-full p-1.5 border rounded-lg text-sm bg-white dark:bg-slate-700 border-slate-300 dark:border-slate-600 text-slate-900 dark:text-white"
                                />
                                <div className="flex gap-2">
                                    {['expense', 'income', 'budget'].map((type) => (
                                        <button
                                            key={type}
                                            type="button"
                                            onClick={() => toggleType(editAppliesTo, type, setEditAppliesTo)}
                                            className={`px-2 py-0.5 rounded-full text-xs font-medium border ${
                                                editAppliesTo.includes(type)
                                                    ? 'bg-primary-100 dark:bg-primary-900/30 border-primary-400 text-primary-700 dark:text-primary-300'
                                                    : 'bg-white dark:bg-slate-700 border-slate-300 dark:border-slate-600 text-slate-400'
                                            }`}
                                        >
                                            {TYPE_LABELS[type]}
                                        </button>
                                    ))}
                                </div>
                            </div>
                        ) : (
                            <div className="flex-1">
                                <div className="flex items-center gap-2">
                                    <span className="font-medium text-slate-900 dark:text-white">
                                        {cat.name}
                                    </span>
                                    {cat.is_standard && (
                                        <Lock className="w-3 h-3 text-slate-400" />
                                    )}
                                </div>
                                <div className="flex gap-1 mt-1">
                                    {cat.applies_to.map((type) => (
                                        <span
                                            key={type}
                                            className="text-xs px-2 py-0.5 bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400 rounded-full"
                                        >
                                            {TYPE_LABELS[type]}
                                        </span>
                                    ))}
                                </div>
                            </div>
                        )}

                        {!cat.is_standard && (
                            <div className="flex gap-1">
                                {editingId === cat.id ? (
                                    <>
                                        <button
                                            onClick={() => handleUpdate(cat)}
                                            className="p-1.5 text-green-600 hover:bg-green-50 dark:hover:bg-green-900/20 rounded-lg"
                                        >
                                            <Check className="w-4 h-4" />
                                        </button>
                                        <button
                                            onClick={() => setEditingId(null)}
                                            className="p-1.5 text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg"
                                        >
                                            <X className="w-4 h-4" />
                                        </button>
                                    </>
                                ) : (
                                    <>
                                        <button
                                            onClick={() => startEdit(cat)}
                                            className="p-1.5 text-slate-400 hover:text-primary-600 hover:bg-primary-50 dark:hover:bg-primary-900/20 rounded-lg"
                                        >
                                            <Pencil className="w-4 h-4" />
                                        </button>
                                        <button
                                            onClick={() => handleDelete(cat)}
                                            className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg"
                                        >
                                            <Trash2 className="w-4 h-4" />
                                        </button>
                                    </>
                                )}
                            </div>
                        )}
                    </div>
                ))}
            </div>
        </div>
    );
};
```

- [ ] **Step 2: Commit**

```bash
git add src/modules/settings/pages/CategoriesPage.tsx
git commit -m "feat: add CategoriesPage for managing user categories"
```

---

## Task 15: Frontend — route + Topbar link

**Files:**
- Modify: `frontend/src/App.tsx`
- Modify: `frontend/src/modules/common/components/Topbar.tsx`

- [ ] **Step 1: Add route in App.tsx**

In `frontend/src/App.tsx`, add the import:

```typescript
import { CategoriesPage } from './modules/settings/pages/CategoriesPage';
```

Inside the `<Route element={<Layout />}>` block, add:

```tsx
<Route path="/settings/categories" element={<CategoriesPage />} />
```

- [ ] **Step 2: Add link in Topbar profile dropdown**

In `frontend/src/modules/common/components/Topbar.tsx`, add `Settings` import from `lucide-react` (add to the existing import):

```typescript
Settings,
```

In the profile dropdown `<div className="p-1">` section, add a "Categories" link before the Sign out button:

```tsx
<Link
    to="/settings/categories"
    onClick={() => setIsProfileOpen(false)}
    className="w-full text-left px-3 py-2 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 rounded-xl flex items-center gap-2 transition-colors"
>
    <Settings className="w-4 h-4" />
    Categories
</Link>
```

- [ ] **Step 3: Verify**

Start the dev server (`npm run dev`), log in, click the profile dropdown, click "Categories", and confirm the categories list loads.

- [ ] **Step 4: Commit**

```bash
git add src/App.tsx src/modules/common/components/Topbar.tsx
git commit -m "feat: add /settings/categories route and Topbar link"
```

---

## Task 16: Frontend — dynamic category in AddExpenseForm

**Files:**
- Modify: `frontend/src/modules/expense/components/AddExpenseForm.tsx`

- [ ] **Step 1: Replace hardcoded category `<select>` with dynamic options**

In `frontend/src/modules/expense/components/AddExpenseForm.tsx`:

1. Add import at top:

```typescript
import { getCategories, Category } from '../../../api/categories';
```

2. Add state inside the component:

```typescript
const [categories, setCategories] = useState<Category[]>([]);
```

3. Add a `useEffect` to load categories (add after existing useEffects):

```typescript
useEffect(() => {
    getCategories('expense').then(setCategories).catch(() => {});
}, []);
```

4. Find the category `<select>` (around line 636) and replace the static `<option>` lines with dynamic ones:

```tsx
<select
    value={formData.category_id || ''}
    onChange={(e) => setFormData({ ...formData, category_id: e.target.value })}
    className="w-full p-2 border rounded-lg ..."
>
    <option value="">Select category</option>
    {categories.map((cat) => (
        <option key={cat.id} value={cat.id}>
            {cat.name}
        </option>
    ))}
</select>
```

5. Update `formData` initial state: replace `category: 'Food'` (or similar) with `category_id: ''`.

6. Update the submit payload: replace `category: formData.category` with `category_id: formData.category_id`.

- [ ] **Step 2: Verify**

Open the Add Expense form in the browser. The category dropdown should show your user's categories (Food, Transport, etc.) loaded from the API.

- [ ] **Step 3: Commit**

```bash
git add src/modules/expense/components/AddExpenseForm.tsx
git commit -m "feat: use dynamic category dropdown in AddExpenseForm"
```

---

## Task 17: Frontend — dynamic category in BudgetForm

**Files:**
- Modify: `frontend/src/modules/expense/components/BudgetForm.tsx`

- [ ] **Step 1: Replace hardcoded options with dynamic categories**

In `frontend/src/modules/expense/components/BudgetForm.tsx`:

1. Add import:

```typescript
import { getCategories, Category } from '../../../api/categories';
```

2. Add state and effect:

```typescript
const [categories, setCategories] = useState<Category[]>([]);

useEffect(() => {
    getCategories('budget').then(setCategories).catch(() => {});
}, []);
```

3. Replace `formData.category` initial state with `category_id: ''`.

4. Replace the static `<option>` lines in the category `<select>` (around line 50) with:

```tsx
<select
    value={formData.category_id || ''}
    onChange={(e) => setFormData({ ...formData, category_id: e.target.value })}
    required
    className="w-full p-2 border rounded-lg ..."
>
    <option value="">Select category</option>
    {categories.map((cat) => (
        <option key={cat.id} value={cat.id}>
            {cat.name}
        </option>
    ))}
</select>
```

5. Update submit payload: replace `category: formData.category` with `category_id: formData.category_id`.

- [ ] **Step 2: Commit**

```bash
git add src/modules/expense/components/BudgetForm.tsx
git commit -m "feat: use dynamic category dropdown in BudgetForm"
```

---

## Task 18: Frontend — dynamic category in IncomeForm and IncomeDetailsPage

**Files:**
- Modify: `frontend/src/modules/income/components/IncomeForm.tsx`
- Modify: `frontend/src/modules/income/pages/IncomeDetailsPage.tsx`

- [ ] **Step 1: Update IncomeForm**

In `frontend/src/modules/income/components/IncomeForm.tsx`:

1. Add import:

```typescript
import { getCategories, Category } from '../../../api/categories';
```

2. Add state and effect:

```typescript
const [categories, setCategories] = useState<Category[]>([]);

useEffect(() => {
    getCategories('income').then(setCategories).catch(() => {});
}, []);
```

3. Update initial `formData`: replace `category: ''` with `category_id: ''`.

4. Replace the category `<input type="text">` with a `<select>`:

```tsx
<select
    value={formData.category_id || ''}
    onChange={(e) => setFormData({ ...formData, category_id: e.target.value })}
    className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-green-500 outline-none bg-white dark:bg-slate-700 border-gray-300 dark:border-slate-600 text-gray-900 dark:text-white"
>
    <option value="">Select category</option>
    {categories.map((cat) => (
        <option key={cat.id} value={cat.id}>
            {cat.name}
        </option>
    ))}
</select>
```

5. Update submit payload: replace `category: formData.category` with `category_id: formData.category_id`.

- [ ] **Step 2: Update IncomeDetailsPage**

Apply the same pattern to `frontend/src/modules/income/pages/IncomeDetailsPage.tsx`:
- Replace `category: ''` in form state with `category_id: ''`
- Add `getCategories` import and effect
- Replace category `<input>` with `<select>` using dynamic options
- Replace `category: response.income.category` with `category_id: response.income.category_id` when loading existing income

- [ ] **Step 3: Commit**

```bash
git add src/modules/income/components/IncomeForm.tsx src/modules/income/pages/IncomeDetailsPage.tsx
git commit -m "feat: use dynamic category dropdown in IncomeForm and IncomeDetailsPage"
```

---

## Task 19: Flutter — Category model + repository

**Files:**
- Create: `square_app/lib/features/categories/data/category_model.dart`
- Create: `square_app/lib/features/categories/data/categories_repository.dart`

- [ ] **Step 1: Create category model**

```bash
mkdir -p square_app/lib/features/categories/data
```

Create `square_app/lib/features/categories/data/category_model.dart`:

```dart
class Category {
  final String id;
  final String name;
  final List<String> appliesTo;
  final bool isStandard;

  const Category({
    required this.id,
    required this.name,
    required this.appliesTo,
    required this.isStandard,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        appliesTo: List<String>.from(json['applies_to'] as List),
        isStandard: json['is_standard'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'applies_to': appliesTo,
      };

  Category copyWith({String? name, List<String>? appliesTo}) => Category(
        id: id,
        name: name ?? this.name,
        appliesTo: appliesTo ?? this.appliesTo,
        isStandard: isStandard,
      );
}
```

- [ ] **Step 2: Create categories repository**

Create `square_app/lib/features/categories/data/categories_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:square_app/core/constants/api_constants.dart';
import 'category_model.dart';

class CategoriesRepository {
  final Dio _dio;

  CategoriesRepository({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<List<Category>> getCategories(String token, {String? appliesTo}) async {
    final queryParams = appliesTo != null ? {'applies_to': appliesTo} : null;
    final response = await _dio.get(
      '/categories',
      queryParameters: queryParams,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> createCategory(
      String token, String name, List<String> appliesTo) async {
    final response = await _dio.post(
      '/categories',
      data: {'name': name, 'applies_to': appliesTo},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Category> updateCategory(
      String token, String id, String name, List<String> appliesTo) async {
    final response = await _dio.patch(
      '/categories/$id',
      data: {'name': name, 'applies_to': appliesTo},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String token, String id) async {
    await _dio.delete(
      '/categories/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd square_app
git add lib/features/categories/data/
git commit -m "feat: add Category model and CategoriesRepository"
```

---

## Task 20: Flutter — Categories provider

**Files:**
- Create: `square_app/lib/features/categories/presentation/categories_provider.dart`

- [ ] **Step 1: Create provider**

```bash
mkdir -p square_app/lib/features/categories/presentation
```

Create `square_app/lib/features/categories/presentation/categories_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/category_model.dart';
import '../data/categories_repository.dart';

final categoriesRepositoryProvider =
    Provider((_) => CategoriesRepository());

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return ref.read(categoriesRepositoryProvider).getCategories(token);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      return ref.read(categoriesRepositoryProvider).getCategories(token);
    });
  }

  Future<void> create(String name, List<String> appliesTo) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await ref.read(categoriesRepositoryProvider).createCategory(token, name, appliesTo);
    await refresh();
  }

  Future<void> update(String id, String name, List<String> appliesTo) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await ref.read(categoriesRepositoryProvider).updateCategory(token, id, name, appliesTo);
    await refresh();
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await ref.read(categoriesRepositoryProvider).deleteCategory(token, id);
    await refresh();
  }

  List<Category> forType(String type) {
    final cats = state.value;
    if (cats == null) return [];
    return cats.where((c) => c.appliesTo.contains(type)).toList();
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/categories/presentation/categories_provider.dart
git commit -m "feat: add CategoriesNotifier provider with CRUD operations"
```

---

## Task 21: Flutter — Categories settings screen

**Files:**
- Create: `square_app/lib/features/categories/presentation/categories_settings_screen.dart`

- [ ] **Step 1: Create the screen**

Create `square_app/lib/features/categories/presentation/categories_settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/category_model.dart';
import 'categories_provider.dart';

class CategoriesSettingsScreen extends ConsumerStatefulWidget {
  const CategoriesSettingsScreen({super.key});

  @override
  ConsumerState<CategoriesSettingsScreen> createState() =>
      _CategoriesSettingsScreenState();
}

class _CategoriesSettingsScreenState
    extends ConsumerState<CategoriesSettingsScreen> {
  final _nameController = TextEditingController();
  List<String> _selectedTypes = ['expense', 'income', 'budget'];
  bool _showForm = false;
  String? _editingId;
  final _editNameController = TextEditingController();
  List<String> _editTypes = [];

  static const _typeLabels = {
    'expense': 'Expense',
    'income': 'Income',
    'budget': 'Budget',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _editNameController.dispose();
    super.dispose();
  }

  void _toggleType(List<String> types, String type, void Function(List<String>) setter) {
    setState(() {
      if (types.contains(type)) {
        if (types.length > 1) setter(types.where((t) => t != type).toList());
      } else {
        setter([...types, type]);
      }
    });
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    try {
      await ref.read(categoriesProvider.notifier).create(name, _selectedTypes);
      _nameController.clear();
      setState(() {
        _showForm = false;
        _selectedTypes = ['expense', 'income', 'budget'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _update(String id) async {
    final name = _editNameController.text.trim();
    if (name.isEmpty) return;
    try {
      await ref.read(categoriesProvider.notifier).update(id, name, _editTypes);
      setState(() => _editingId = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _delete(Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            'Deleting "${cat.name}" will move all its records to "Other". Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(categoriesProvider.notifier).delete(cat.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (categories) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_showForm) _buildCreateForm(isDark),
            ...categories.map((cat) => _buildCategoryTile(cat, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.slate[700]! : AppColors.slate[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Category name',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['expense', 'income', 'budget'].map((type) {
              final selected = _selectedTypes.contains(type);
              return FilterChip(
                label: Text(_typeLabels[type]!),
                selected: selected,
                onSelected: (_) => _toggleType(_selectedTypes, type, (v) => _selectedTypes = v),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _create,
                  child: const Text('Create'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _showForm = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(Category cat, bool isDark) {
    final isEditing = _editingId == cat.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.slate[700]! : AppColors.slate[200]!),
      ),
      child: isEditing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _editNameController,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['expense', 'income', 'budget'].map((type) {
                    final selected = _editTypes.contains(type);
                    return FilterChip(
                      label: Text(_typeLabels[type]!),
                      selected: selected,
                      onSelected: (_) => _toggleType(_editTypes, type, (v) => _editTypes = v),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _update(cat.id),
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _editingId = null),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.slate[900],
                            ),
                          ),
                          if (cat.isStandard) ...[
                            const SizedBox(width: 6),
                            Icon(LucideIcons.lock, size: 12, color: AppColors.slate[400]),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: cat.appliesTo.map((type) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.slate[700] : AppColors.slate[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _typeLabels[type] ?? type,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.slate[300] : AppColors.slate[600],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                if (!cat.isStandard) ...[
                  IconButton(
                    icon: Icon(LucideIcons.pencil, size: 16, color: AppColors.slate[400]),
                    onPressed: () {
                      setState(() {
                        _editingId = cat.id;
                        _editNameController.text = cat.name;
                        _editTypes = [...cat.appliesTo];
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                    onPressed: () => _delete(cat),
                  ),
                ],
              ],
            ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/categories/presentation/categories_settings_screen.dart
git commit -m "feat: add CategoriesSettingsScreen for Flutter"
```

---

## Task 22: Flutter — Update router + profile screen

**Files:**
- Modify: `square_app/lib/core/router.dart`
- Modify: `square_app/lib/features/profile/presentation/profile_screen.dart`

- [ ] **Step 1: Add import and route in router.dart**

In `square_app/lib/core/router.dart`:

1. Add import:

```dart
import '../../features/categories/presentation/categories_settings_screen.dart';
```

2. Inside the `/profile` GoRoute's `routes` list, add:

```dart
GoRoute(
  path: 'categories',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) => const CategoriesSettingsScreen(),
),
```

- [ ] **Step 2: Add "Categories" option in profile screen**

In `square_app/lib/features/profile/presentation/profile_screen.dart`, add a new `_buildProfileOption` call inside the `GlassContainer` children list, after the "Features" option:

```dart
_buildProfileOption(
  context,
  icon: LucideIcons.tag,
  title: 'Categories',
  onTap: () => context.push('/profile/categories'),
),
```

- [ ] **Step 3: Verify**

Run `flutter run`, navigate to Profile, tap "Categories", and confirm the categories screen loads.

- [ ] **Step 4: Commit**

```bash
git add lib/core/router.dart lib/features/profile/presentation/profile_screen.dart
git commit -m "feat: add /profile/categories route and profile menu entry"
```

---

## Task 23: Flutter — Update expense form (dynamic category dropdown)

**Files:**
- Modify: `square_app/lib/features/expense/data/expense_model.dart`
- Modify: `square_app/lib/features/expense/presentation/screens/add_edit_expense_screen.dart`

- [ ] **Step 1: Update ExpenseModel**

In `square_app/lib/features/expense/data/expense_model.dart`:

Replace `final String category;` with:

```dart
final String categoryId;
final String categoryName;
```

Update the constructor, `fromJson`, and `toJson`:

```dart
// Constructor
required this.categoryId,
required this.categoryName,

// fromJson
categoryId: json['category_id'] ?? '',
categoryName: json['category_name'] ?? 'General',

// toJson
'category_id': categoryId,
'category_name': categoryName,
```

- [ ] **Step 2: Fix any compile errors from category → categoryId/categoryName**

Search for `expense.category` in the codebase and update references:
- `expense_card.dart`: `expense.category` → `expense.categoryName`
- `expense_detail_screen.dart`: replace `'Category', expense.category` with `'Category', expense.categoryName`

```bash
grep -rn "\.category" square_app/lib/features/expense/ --include="*.dart"
```

Update each occurrence.

- [ ] **Step 3: Update add_edit_expense_screen.dart**

In `square_app/lib/features/expense/presentation/screens/add_edit_expense_screen.dart`:

1. Add import at top:

```dart
import '../../../categories/presentation/categories_provider.dart';
import '../../../categories/data/category_model.dart';
```

2. Replace `late TextEditingController _categoryController;` with:

```dart
String? _selectedCategoryId;
```

3. In `initState`, remove `_categoryController` initialization. Set initial value:

```dart
_selectedCategoryId = widget.expense?.categoryId;
```

4. Remove `_categoryController.dispose()` from `dispose`.

5. In the form submit payload, replace:

```dart
'category': _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim(),
```

with:

```dart
'category_id': _selectedCategoryId ?? '',
```

6. Replace the category chip/input section (the `children: ['Food', 'Transport', ...]` area) with a dynamic `DropdownButtonFormField`:

```dart
Consumer(
  builder: (context, ref, _) {
    final catsAsync = ref.watch(categoriesProvider);
    final cats = catsAsync.value?.where((c) => c.appliesTo.contains('expense')).toList() ?? [];
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      hint: const Text('Select category'),
      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
      items: cats.map((cat) => DropdownMenuItem(
        value: cat.id,
        child: Text(cat.name),
      )).toList(),
      onChanged: (val) => setState(() => _selectedCategoryId = val),
    );
  },
),
```

- [ ] **Step 4: Run and verify**

```bash
flutter run
```

Navigate to Add Expense, confirm the category dropdown shows the user's categories.

- [ ] **Step 5: Commit**

```bash
git add lib/features/expense/data/expense_model.dart \
        lib/features/expense/presentation/screens/add_edit_expense_screen.dart \
        lib/features/expense/presentation/widgets/expense_card.dart \
        lib/features/expense/presentation/screens/expense_detail_screen.dart
git commit -m "feat: use dynamic category dropdown in expense forms and update ExpenseModel"
```

---

## Task 24: Flutter — Add category field to income form

**Files:**
- Modify: `square_app/lib/features/transactions/data/income_model.dart`
- Modify: `square_app/lib/features/transactions/presentation/screens/add_edit_income_screen.dart`

- [ ] **Step 1: Update Income model**

In `square_app/lib/features/transactions/data/income_model.dart`, add fields:

```dart
final String categoryId;
final String categoryName;
```

Update constructor, `fromJson`, `toJson`:

```dart
// Constructor
required this.categoryId,
required this.categoryName,

// fromJson
categoryId: json['category_id'] ?? '',
categoryName: json['category_name'] ?? 'General',

// toJson (in toJson map)
'category_id': categoryId,
```

- [ ] **Step 2: Update AddEditIncomeScreen**

In `square_app/lib/features/transactions/presentation/screens/add_edit_income_screen.dart`:

1. Add import:

```dart
import '../../../categories/presentation/categories_provider.dart';
```

2. Add state field:

```dart
String? _selectedCategoryId;
```

3. In the submit `data` map, add:

```dart
'category_id': _selectedCategoryId ?? '',
```

4. Add a `DropdownButtonFormField` for category in the form (before the submit button), using `Consumer` to watch `categoriesProvider` and filter by `'income'`:

```dart
Consumer(
  builder: (context, ref, _) {
    final cats = ref.watch(categoriesProvider).value
        ?.where((c) => c.appliesTo.contains('income'))
        .toList() ?? [];
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      hint: const Text('Select category'),
      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
      items: cats.map((cat) => DropdownMenuItem(
        value: cat.id,
        child: Text(cat.name),
      )).toList(),
      onChanged: (val) => setState(() => _selectedCategoryId = val),
    );
  },
),
```

- [ ] **Step 3: Verify**

```bash
flutter run
```

Navigate to Add Income, confirm category dropdown appears and shows income-applicable categories.

- [ ] **Step 4: Commit**

```bash
git add lib/features/transactions/data/income_model.dart \
        lib/features/transactions/presentation/screens/add_edit_income_screen.dart
git commit -m "feat: add category field to income form and Income model"
```

---

## Self-Review Checklist

- [x] All 9 standard categories seeded at signup (Task 2–3)
- [x] Standard categories blocked from delete and rename (Task 8)
- [x] Delete reassigns to "Other" before destroying (Task 8)
- [x] `category_id` + `category_name` returned in all API responses (Tasks 9–12)
- [x] `applies_to` filter on GET /categories used by all forms (Tasks 16–18, 23–24)
- [x] Budget uniqueness constraint migrated from category string to category_id (Task 6)
- [x] Dashboard serializer updated (Task 12)
- [x] Expense `with_sort` no longer references dropped `category` column (Task 7)
- [x] Flutter expense model updated (`categoryId`/`categoryName`) with downstream fixes (Task 23)
- [x] No TBDs or placeholders in any task
