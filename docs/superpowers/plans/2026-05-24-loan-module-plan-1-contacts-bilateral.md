# Loan Module — Plan 1: Contacts + Bilateral Loans

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-user personal loan ledger with a bilateral system where both lender and borrower see the same loan record, backed by a contacts system for counterparty identity.

**Architecture:** Single shared `loans` row with `lender_user_id` (owner, full access) and `borrower_user_id` (nullable, read-only). A new `contacts` table gives each user a list of counterparties that can be platform users or off-platform contacts. Existing `loan_type` and `counterparty_name` columns are dropped; direction is inferred from which side the current user is on.

**Tech Stack:** Rails 7.2, PostgreSQL, minitest + factory_bot_rails + faker, Flutter + Riverpod + Dio.

---

## Part A: Rails Backend

---

### Task 1: Test Infrastructure

**Files:**
- Modify: `rails_backend/Gemfile`
- Create: `rails_backend/test/test_helper.rb`
- Create: `rails_backend/test/factories/users.rb`
- Create: `rails_backend/test/factories/contacts.rb`
- Create: `rails_backend/test/factories/loans.rb`

- [ ] **Step 1: Add test gems**

In `rails_backend/Gemfile`, replace the `group :development, :test` block:

```ruby
group :development, :test do
  gem "dotenv-rails"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.3"
end

group :test do
  gem "shoulda-matchers", "~> 6.2"
end
```

- [ ] **Step 2: Install gems**

```bash
cd rails_backend && bundle install
```

Expected: Bundle complete, no errors.

- [ ] **Step 3: Write test helper**

Create `rails_backend/test/test_helper.rb`:

```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "factory_bot_rails"

Shoulda::Matchers.configure do |config|
  config.integrate { |with| with.test_framework(:minitest).library(:rails) }
end

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  fixtures :none
end

class ActionDispatch::IntegrationTest
  include FactoryBot::Syntax::Methods

  def auth_header(user)
    token = JwtService.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end
end
```

- [ ] **Step 4: Create user factory**

Create `rails_backend/test/factories/users.rb`:

```ruby
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    password   { "password123" }
    mobile_number { nil }
  end
end
```

- [ ] **Step 5: Create contact factory (placeholder — will be valid after Task 3)**

Create `rails_backend/test/factories/contacts.rb`:

```ruby
FactoryBot.define do
  factory :contact do
    association :owner, factory: :user
    linked_user { nil }
    name  { Faker::Name.full_name }
    phone { nil }
    email { nil }
  end
end
```

- [ ] **Step 6: Create loan factory (placeholder — will be valid after Task 4)**

Create `rails_backend/test/factories/loans.rb`:

```ruby
FactoryBot.define do
  factory :loan do
    association :lender, factory: :user
    borrower      { nil }
    association :contact
    amount        { 5000.00 }
    date          { Time.current }
    due_date      { nil }
    status        { "PENDING" }
    confirmation_status { "pending" }
    interest_mode { "none" }
    description   { "Test loan" }
    category      { nil }
  end
end
```

- [ ] **Step 7: Verify test setup**

```bash
cd rails_backend && bin/rails test 2>&1 | head -20
```

Expected: `0 runs, 0 assertions, 0 failures, 0 errors` (no tests yet, just verifies setup loads).

- [ ] **Step 8: Commit**

```bash
git add rails_backend/Gemfile rails_backend/Gemfile.lock rails_backend/test/
git commit -m "chore: add test infrastructure (minitest + factory_bot + faker)"
```

---

### Task 2: Add mobile_number to Users

**Files:**
- Create: `rails_backend/db/migrate/20260524140000_add_mobile_number_to_users.rb`
- Modify: `rails_backend/db/schema.rb` (auto-updated by migration)
- Create: `rails_backend/test/models/user_test.rb`

- [ ] **Step 1: Write failing test**

Create `rails_backend/test/models/user_test.rb`:

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "can set and retrieve mobile_number" do
    user = create(:user, mobile_number: "+91 98765 43210")
    user.reload
    assert_equal "+91 98765 43210", user.mobile_number
  end

  test "mobile_number defaults to nil" do
    user = create(:user)
    assert_nil user.mobile_number
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd rails_backend && bin/rails test test/models/user_test.rb -v
```

Expected: `Error: unknown attribute 'mobile_number'`

- [ ] **Step 3: Generate and write migration**

```bash
cd rails_backend && bin/rails generate migration AddMobileNumberToUsers mobile_number:string
```

Open the generated file (path printed by the command) and verify it contains:

```ruby
class AddMobileNumberToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :mobile_number, :string
  end
end
```

- [ ] **Step 4: Run migration**

```bash
cd rails_backend && bin/rails db:migrate
```

Expected: `== AddMobileNumberToUsers: migrated`

- [ ] **Step 5: Run test to verify it passes**

```bash
cd rails_backend && bin/rails test test/models/user_test.rb -v
```

Expected: `2 runs, 2 assertions, 0 failures, 0 errors`

- [ ] **Step 6: Commit**

```bash
git add rails_backend/db/ rails_backend/test/models/user_test.rb
git commit -m "feat: add mobile_number to users"
```

---

### Task 3: Create Contacts Table and Model

**Files:**
- Create: `rails_backend/db/migrate/20260524141000_create_contacts.rb`
- Create: `rails_backend/app/models/contact.rb`
- Modify: `rails_backend/app/models/user.rb`
- Create: `rails_backend/test/models/contact_test.rb`

- [ ] **Step 1: Write failing model tests**

Create `rails_backend/test/models/contact_test.rb`:

```ruby
require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "valid contact saves" do
    owner = create(:user)
    contact = Contact.new(owner_user_id: owner.id, name: "Rahul")
    assert contact.valid?
  end

  test "requires name" do
    owner = create(:user)
    contact = Contact.new(owner_user_id: owner.id)
    assert_not contact.valid?
    assert_includes contact.errors[:name], "can't be blank"
  end

  test "requires owner_user_id" do
    contact = Contact.new(name: "Rahul")
    assert_not contact.valid?
  end

  test "on_platform? returns true when linked_user_id set" do
    owner = create(:user)
    linked = create(:user)
    contact = create(:contact, owner: owner, linked_user: linked)
    assert contact.on_platform?
  end

  test "on_platform? returns false when no linked_user_id" do
    contact = create(:contact)
    assert_not contact.on_platform?
  end

  test "search finds contacts by name" do
    owner = create(:user)
    rahul = create(:contact, owner: owner, name: "Rahul Sharma")
    _other = create(:contact, owner: owner, name: "Priya")

    results = Contact.search_for(owner.id, "rahul")
    assert_includes results[:contacts].map(&:id), rahul.id
  end

  test "search finds platform users not yet in contacts" do
    owner = create(:user)
    platform_user = create(:user, username: "neha123", email: "neha@example.com")

    results = Contact.search_for(owner.id, "neha")
    assert_includes results[:platform_users].map(&:id), platform_user.id
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd rails_backend && bin/rails test test/models/contact_test.rb -v
```

Expected: `NameError: uninitialized constant Contact`

- [ ] **Step 3: Generate migration**

```bash
cd rails_backend && bin/rails generate migration CreateContacts
```

Open the generated file and replace its contents with:

```ruby
class CreateContacts < ActiveRecord::Migration[7.2]
  def change
    create_table :contacts do |t|
      t.bigint :owner_user_id, null: false
      t.bigint :linked_user_id
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.timestamps
    end

    add_index :contacts, :owner_user_id
    add_index :contacts, :linked_user_id
    add_foreign_key :contacts, :users, column: :owner_user_id
    add_foreign_key :contacts, :users, column: :linked_user_id
  end
end
```

- [ ] **Step 4: Run migration**

```bash
cd rails_backend && bin/rails db:migrate
```

Expected: `== CreateContacts: migrated`

- [ ] **Step 5: Create Contact model**

Create `rails_backend/app/models/contact.rb`:

```ruby
class Contact < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: :owner_user_id
  belongs_to :linked_user, class_name: "User", foreign_key: :linked_user_id, optional: true

  validates :name, presence: true
  validates :owner_user_id, presence: true

  def on_platform?
    linked_user_id.present?
  end

  def self.search_for(owner_user_id, query)
    q = "%#{sanitize_sql_like(query.to_s.downcase)}%"

    contacts = where(owner_user_id: owner_user_id)
                 .where("LOWER(name) LIKE ? OR phone LIKE ? OR LOWER(email) LIKE ?", q, q, q)

    already_linked_ids = where(owner_user_id: owner_user_id)
                           .where.not(linked_user_id: nil)
                           .pluck(:linked_user_id)

    platform_users = User.where.not(id: [owner_user_id, *already_linked_ids])
                         .where("LOWER(username) LIKE ? OR mobile_number LIKE ? OR LOWER(email) LIKE ?", q, q, q)
                         .limit(5)

    { contacts: contacts, platform_users: platform_users }
  end
end
```

- [ ] **Step 6: Update User model associations**

In `rails_backend/app/models/user.rb`, add after the existing `has_many` block:

```ruby
has_many :owned_contacts, class_name: "Contact", foreign_key: :owner_user_id, dependent: :destroy
```

- [ ] **Step 7: Run tests to verify they pass**

```bash
cd rails_backend && bin/rails test test/models/contact_test.rb -v
```

Expected: `7 runs, 7 assertions, 0 failures, 0 errors`

- [ ] **Step 8: Commit**

```bash
git add rails_backend/db/ rails_backend/app/models/contact.rb rails_backend/app/models/user.rb rails_backend/test/models/contact_test.rb
git commit -m "feat: add contacts table and model"
```

---

### Task 4: Revamp Loans Table — Schema + Data Migration

**Files:**
- Create: `rails_backend/db/migrate/20260524142000_revamp_loans_for_bilateral.rb`
- Modify: `rails_backend/db/schema.rb` (auto-updated)

- [ ] **Step 1: Generate migration**

```bash
cd rails_backend && bin/rails generate migration RevampLoansForBilateral
```

Open the generated file and replace its contents with:

```ruby
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
    change_column_null :loans, :lender_user_id, false
    change_column_null :loans, :contact_id, false

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
```

- [ ] **Step 2: Run migration**

```bash
cd rails_backend && bin/rails db:migrate
```

Expected: `== RevampLoansForBilateral: migrated`

- [ ] **Step 3: Verify schema looks right**

```bash
cd rails_backend && bin/rails db:schema:dump && grep -A 30 'create_table "loans"' db/schema.rb
```

Expected output includes `lender_user_id`, `borrower_user_id`, `contact_id`, `confirmation_status`, `interest_mode`. Does NOT include `user_id`, `counterparty_name`, `loan_type`.

- [ ] **Step 4: Commit**

```bash
git add rails_backend/db/
git commit -m "feat: revamp loans table for bilateral model (data migration included)"
```

---

### Task 5: Loan Model — Revamp

**Files:**
- Modify: `rails_backend/app/models/loan.rb`
- Modify: `rails_backend/app/models/user.rb`
- Modify: `rails_backend/test/factories/loans.rb` (contact association now exists)
- Create: `rails_backend/test/models/loan_test.rb`

- [ ] **Step 1: Write failing tests**

Create `rails_backend/test/models/loan_test.rb`:

```ruby
require "test_helper"

class LoanTest < ActiveSupport::TestCase
  test "valid loan saves" do
    lender = create(:user)
    contact = create(:contact, owner: lender)
    loan = Loan.new(
      lender_user_id: lender.id,
      contact_id: contact.id,
      amount: 5000,
      date: Time.current,
      status: "PENDING",
      interest_mode: "none"
    )
    assert loan.valid?
  end

  test "requires due_date when interest_mode is penalty" do
    lender = create(:user)
    contact = create(:contact, owner: lender)
    loan = Loan.new(
      lender_user_id: lender.id,
      contact_id: contact.id,
      amount: 5000,
      date: Time.current,
      status: "PENDING",
      interest_mode: "penalty"
    )
    assert_not loan.valid?
    assert_includes loan.errors[:due_date], "can't be blank"
  end

  test "due_date not required for interest_mode none" do
    lender = create(:user)
    contact = create(:contact, owner: lender)
    loan = Loan.new(
      lender_user_id: lender.id, contact_id: contact.id,
      amount: 5000, date: Time.current, status: "PENDING", interest_mode: "none"
    )
    assert loan.valid?
  end

  test "for_user scope returns loans where user is lender" do
    lender = create(:user)
    contact = create(:contact, owner: lender)
    loan = create(:loan, lender: lender, contact: contact)
    assert_includes Loan.for_user(lender.id), loan
  end

  test "for_user scope returns loans where user is borrower" do
    lender = create(:user)
    borrower = create(:user)
    contact = create(:contact, owner: lender, linked_user: borrower)
    loan = create(:loan, lender: lender, borrower: borrower, contact: contact)
    assert_includes Loan.for_user(borrower.id), loan
  end

  test "lender_for? returns true when user is the lender" do
    lender = create(:user)
    contact = create(:contact, owner: lender)
    loan = create(:loan, lender: lender, contact: contact)
    assert loan.lender_for?(lender.id)
  end

  test "lender_for? returns false when user is the borrower" do
    lender = create(:user)
    borrower = create(:user)
    contact = create(:contact, owner: lender, linked_user: borrower)
    loan = create(:loan, lender: lender, borrower: borrower, contact: contact)
    assert_not loan.lender_for?(borrower.id)
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd rails_backend && bin/rails test test/models/loan_test.rb -v
```

Expected: errors about missing associations/validations.

- [ ] **Step 3: Rewrite Loan model**

Replace `rails_backend/app/models/loan.rb` with:

```ruby
class Loan < ApplicationRecord
  STATUSES             = %w[PENDING PARTIAL PAID].freeze
  CONFIRMATION_STATUSES = %w[pending confirmed disputed].freeze
  INTEREST_MODES       = %w[none from_start penalty].freeze
  INTEREST_PERIODS     = %w[daily monthly annual].freeze
  INTEREST_BASES       = %w[principal total].freeze

  belongs_to :lender,   class_name: "User",    foreign_key: :lender_user_id
  belongs_to :borrower, class_name: "User",    foreign_key: :borrower_user_id, optional: true
  belongs_to :contact
  belongs_to :category, optional: true
  has_many :activity_logs, as: :loggable, dependent: :destroy
  has_many :comments,      as: :commentable, dependent: :destroy

  validates :lender_user_id, :contact_id, :amount, :date, :status, presence: true
  validates :status,               inclusion: { in: STATUSES }
  validates :confirmation_status,  inclusion: { in: CONFIRMATION_STATUSES }
  validates :interest_mode,        inclusion: { in: INTEREST_MODES }, allow_nil: true
  validates :interest_period,      inclusion: { in: INTEREST_PERIODS }, allow_nil: true
  validates :interest_basis,       inclusion: { in: INTEREST_BASES }, allow_nil: true
  validates :amount,               numericality: { greater_than: 0 }
  validates :due_date,             presence: true, if: -> { interest_mode == "penalty" }

  scope :for_user, ->(user_id) {
    where("lender_user_id = ? OR borrower_user_id = ?", user_id, user_id)
  }

  def lender_for?(user_id)
    lender_user_id == user_id
  end
end
```

- [ ] **Step 4: Update User model**

In `rails_backend/app/models/user.rb`:
- Remove: `has_many :loans, dependent: :destroy`
- Add:

```ruby
has_many :lent_loans,     class_name: "Loan", foreign_key: :lender_user_id, dependent: :destroy
has_many :borrowed_loans, class_name: "Loan", foreign_key: :borrower_user_id, dependent: :nullify
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd rails_backend && bin/rails test test/models/loan_test.rb -v
```

Expected: `7 runs, 7 assertions, 0 failures, 0 errors`

- [ ] **Step 6: Commit**

```bash
git add rails_backend/app/models/ rails_backend/test/models/loan_test.rb rails_backend/test/factories/
git commit -m "feat: revamp Loan model for bilateral access + interest modes"
```

---

### Task 6: ContactsController

**Files:**
- Create: `rails_backend/app/controllers/api/v1/contacts_controller.rb`
- Create: `rails_backend/test/controllers/api/v1/contacts_controller_test.rb`

- [ ] **Step 1: Write failing controller tests**

Create `rails_backend/test/controllers/api/v1/contacts_controller_test.rb`:

```ruby
require "test_helper"

class Api::V1::ContactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @headers = auth_header(@user)
  end

  test "GET /api/contacts returns user contacts" do
    create(:contact, owner: @user, name: "Rahul")
    create(:contact, name: "Priya") # belongs to another user — should not appear

    get "/api/contacts", headers: @headers
    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal "Rahul", body.first["name"]
  end

  test "GET /api/contacts/search returns contacts and platform users" do
    create(:contact, owner: @user, name: "Rahul Kumar")
    platform_user = create(:user, username: "neha_s", email: "neha@test.com")

    get "/api/contacts/search", params: { q: "neha" }, headers: @headers
    assert_response :ok
    body = JSON.parse(response.body)
    assert_includes body["platform_users"].map { |u| u["id"] }, platform_user.id.to_s
  end

  test "GET /api/contacts/search returns empty for short query" do
    get "/api/contacts/search", params: { q: "a" }, headers: @headers
    assert_response :ok
    assert_equal [], JSON.parse(response.body)
  end

  test "POST /api/contacts creates off-platform contact" do
    post "/api/contacts", params: { name: "Rahul", phone: "9876543210" }.to_json, headers: @headers
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Rahul", body["name"]
    assert_equal false, body["on_platform"]
  end

  test "POST /api/contacts creates on-platform contact with linked_user_id" do
    platform_user = create(:user)
    post "/api/contacts",
         params: { name: platform_user.display_name, linked_user_id: platform_user.id }.to_json,
         headers: @headers
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal true, body["on_platform"]
    assert_equal platform_user.id.to_s, body["linked_user_id"]
  end

  test "GET /api/contacts/:id/loans returns all loans with that contact" do
    contact = create(:contact, owner: @user)
    loan1 = create(:loan, lender: @user, contact: contact)
    _loan_other = create(:loan) # different contact — should not appear

    get "/api/contacts/#{contact.id}/loans", headers: @headers
    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 1, body["loans"].length
    assert_equal loan1.id.to_s, body["loans"].first["id"]
  end

  test "GET /api/contacts/:id/loans returns 404 for wrong owner" do
    other_user = create(:user)
    contact = create(:contact, owner: other_user)

    get "/api/contacts/#{contact.id}/loans", headers: @headers
    assert_response :not_found
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd rails_backend && bin/rails test test/controllers/api/v1/contacts_controller_test.rb -v
```

Expected: routing errors (controller doesn't exist yet).

- [ ] **Step 3: Create ContactsController**

Create `rails_backend/app/controllers/api/v1/contacts_controller.rb`:

```ruby
module Api
  module V1
    class ContactsController < ApplicationController
      def index
        render json: current_user.owned_contacts.includes(:linked_user).map { |c| serialize(c) }
      end

      def search
        query = params[:q].to_s.strip
        return render json: [] if query.length < 2

        result = Contact.search_for(current_user.id, query)
        render json: {
          contacts:       result[:contacts].map { |c| serialize(c) },
          platform_users: result[:platform_users].map { |u| serialize_platform_user(u) }
        }
      end

      def create
        contact = current_user.owned_contacts.create!(
          name:           params[:name],
          phone:          params[:phone],
          email:          params[:email],
          linked_user_id: params[:linked_user_id]
        )
        render json: serialize(contact), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def loans
        contact = current_user.owned_contacts.find(params[:id])
        loans   = Loan.for_user(current_user.id)
                      .where(contact_id: contact.id)
                      .includes(:contact, :category)
                      .order(date: :desc)

        render json: {
          contact:     serialize(contact),
          loans:       loans.map { |l| serialize_loan(l) },
          net_balance: net_balance(loans)
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Contact not found" }, status: :not_found
      end

      private

      def serialize(c)
        {
          id:             c.id.to_s,
          name:           c.name,
          phone:          c.phone,
          email:          c.email,
          linked_user_id: c.linked_user_id&.to_s,
          on_platform:    c.on_platform?,
          created_at:     c.created_at.iso8601
        }
      end

      def serialize_platform_user(u)
        {
          id:            u.id.to_s,
          username:      u.username,
          name:          u.display_name,
          email:         u.email,
          mobile_number: u.mobile_number,
          on_platform:   true
        }
      end

      def serialize_loan(l)
        direction = l.lender_for?(current_user.id) ? "lent" : "borrowed"
        {
          id:           l.id.to_s,
          direction:    direction,
          amount:       l.amount.to_f,
          status:       l.status,
          date:         l.date.iso8601,
          due_date:     l.due_date&.iso8601,
          description:  l.description,
          category_name: l.category&.name || "",
          interest_mode: l.interest_mode
        }
      end

      def net_balance(loans)
        lent     = loans.select { |l| l.lender_for?(current_user.id) }.sum(&:amount).to_f
        borrowed = loans.reject { |l| l.lender_for?(current_user.id) }.sum(&:amount).to_f
        diff     = lent - borrowed
        {
          direction: diff >= 0 ? "owed_to_you" : "you_owe",
          amount:    diff.abs
        }
      end
    end
  end
end
```

- [ ] **Step 4: Add routes**

In `rails_backend/config/routes.rb`, inside the `scope module: "api/v1"` block, add before `resources :loans`:

```ruby
resources :contacts, only: [:index, :create] do
  collection { get :search }
  member      { get :loans }
end
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd rails_backend && bin/rails test test/controllers/api/v1/contacts_controller_test.rb -v
```

Expected: `6 runs, 6 assertions, 0 failures, 0 errors`

- [ ] **Step 6: Commit**

```bash
git add rails_backend/app/controllers/api/v1/contacts_controller.rb \
        rails_backend/config/routes.rb \
        rails_backend/test/controllers/api/v1/contacts_controller_test.rb
git commit -m "feat: add ContactsController (index, search, create, loans)"
```

---

### Task 7: LoansController — Bilateral + Access Control

**Files:**
- Modify: `rails_backend/app/controllers/api/v1/loans_controller.rb`
- Modify: `rails_backend/config/routes.rb`
- Create: `rails_backend/test/controllers/api/v1/loans_controller_test.rb`

- [ ] **Step 1: Write failing tests**

Create `rails_backend/test/controllers/api/v1/loans_controller_test.rb`:

```ruby
require "test_helper"

class Api::V1::LoansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lender   = create(:user)
    @borrower = create(:user)
    @contact  = create(:contact, owner: @lender, linked_user: @borrower)
    @loan     = create(:loan, lender: @lender, borrower: @borrower, contact: @contact)
  end

  # --- index ---

  test "lender sees their loans in index" do
    get "/api/loans", headers: auth_header(@lender)
    assert_response :ok
    ids = JSON.parse(response.body).map { |l| l["id"] }
    assert_includes ids, @loan.id.to_s
  end

  test "borrower sees loans they are borrowing in index" do
    get "/api/loans", headers: auth_header(@borrower)
    assert_response :ok
    ids = JSON.parse(response.body).map { |l| l["id"] }
    assert_includes ids, @loan.id.to_s
  end

  test "unrelated user does not see loan in index" do
    other = create(:user)
    get "/api/loans", headers: auth_header(other)
    assert_response :ok
    assert_empty JSON.parse(response.body)
  end

  # --- create ---

  test "lender can create a loan with contact_id" do
    post "/api/loans",
         params: {
           contact_id:    @contact.id,
           amount:        3000,
           date:          Date.today.iso8601,
           interest_mode: "none",
           description:   "Test"
         }.to_json,
         headers: auth_header(@lender)
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "PENDING", body["status"]
    assert_equal @contact.id.to_s, body["contact_id"]
  end

  # --- show ---

  test "lender can view loan detail" do
    get "/api/loans/#{@loan.id}", headers: auth_header(@lender)
    assert_response :ok
    assert_equal @loan.id.to_s, JSON.parse(response.body)["loan"]["id"]
  end

  test "borrower can view loan detail (read-only access)" do
    get "/api/loans/#{@loan.id}", headers: auth_header(@borrower)
    assert_response :ok
  end

  test "unrelated user cannot view loan" do
    get "/api/loans/#{@loan.id}", headers: auth_header(create(:user))
    assert_response :not_found
  end

  # --- update ---

  test "lender can update loan" do
    patch "/api/loans/#{@loan.id}",
          params: { description: "Updated" }.to_json,
          headers: auth_header(@lender)
    assert_response :ok
  end

  test "borrower cannot update loan" do
    patch "/api/loans/#{@loan.id}",
          params: { description: "Hack" }.to_json,
          headers: auth_header(@borrower)
    assert_response :forbidden
  end

  # --- destroy ---

  test "lender can delete loan" do
    delete "/api/loans/#{@loan.id}", headers: auth_header(@lender)
    assert_response :ok
  end

  test "borrower cannot delete loan" do
    delete "/api/loans/#{@loan.id}", headers: auth_header(@borrower)
    assert_response :forbidden
  end

  # --- confirmation ---

  test "borrower can update confirmation_status" do
    patch "/api/loans/#{@loan.id}/confirmation",
          params: { confirmation_status: "confirmed" }.to_json,
          headers: auth_header(@borrower)
    assert_response :ok
    assert_equal "confirmed", @loan.reload.confirmation_status
  end

  test "lender cannot update confirmation_status" do
    patch "/api/loans/#{@loan.id}/confirmation",
          params: { confirmation_status: "confirmed" }.to_json,
          headers: auth_header(@lender)
    assert_response :forbidden
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd rails_backend && bin/rails test test/controllers/api/v1/loans_controller_test.rb -v
```

Expected: multiple failures — routing errors, wrong queries, etc.

- [ ] **Step 3: Rewrite LoansController**

Replace `rails_backend/app/controllers/api/v1/loans_controller.rb` with:

```ruby
module Api
  module V1
    class LoansController < ApplicationController
      before_action :set_loan,       only: [:show, :update, :destroy, :comments]
      before_action :set_any_loan,   only: [:confirmation]
      before_action :require_lender, only: [:update, :destroy]
      before_action :require_borrower, only: [:confirmation]

      def index
        loans = Loan.for_user(current_user.id)
                    .includes(:contact, :category)
                    .order(date: :desc)
        render json: loans.map { |l| serialize(l) }
      end

      def show
        logs     = @loan.activity_logs.includes(:user).order(created_at: :desc)
        comments = @loan.comments.includes(:user).order(created_at: :asc)
        render json: {
          loan:     serialize(@loan),
          logs:     serialize_logs(logs),
          comments: serialize_comments(comments)
        }
      end

      def create
        contact = current_user.owned_contacts.find(params[:contact_id])
        loan    = Loan.create!(loan_params.merge(
          lender_user_id: current_user.id,
          contact_id:     contact.id,
          borrower_user_id: contact.linked_user_id
        ))
        render json: serialize(loan), status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Contact not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def update
        changes = changed_fields
        if @loan.update(loan_params)
          log_activity(loggable: @loan, action: "UPDATE", details: changes.join(", ")) if changes.any?
          render json: { message: "Loan updated" }
        else
          render json: { error: @loan.errors.full_messages.first }, status: :bad_request
        end
      end

      def destroy
        @loan.destroy!
        render json: { message: "Loan deleted" }
      end

      def comments
        comment = Comment.create!(commentable: @loan, user: current_user, text: params[:text])
        log_activity(loggable: @loan, action: "COMMENT", details: params[:text])
        render json: serialize_comment(comment), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      def confirmation
        status = params[:confirmation_status]
        unless Loan::CONFIRMATION_STATUSES.include?(status)
          return render json: { error: "Invalid confirmation_status" }, status: :bad_request
        end
        @loan.update!(
          confirmation_status: status,
          confirmed_at: status == "confirmed" ? Time.current : nil
        )
        render json: { message: "Confirmation updated", confirmation_status: @loan.confirmation_status }
      end

      private

      def set_loan
        @loan = Loan.for_user(current_user.id).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Loan not found" }, status: :not_found
      end

      def set_any_loan
        @loan = Loan.for_user(current_user.id).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Loan not found" }, status: :not_found
      end

      def require_lender
        return if @loan.lender_for?(current_user.id)
        render json: { error: "Forbidden" }, status: :forbidden
      end

      def require_borrower
        return unless @loan.lender_for?(current_user.id)
        render json: { error: "Forbidden" }, status: :forbidden
      end

      def loan_params
        params.permit(:amount, :date, :due_date, :status, :description,
                      :category_id, :interest_mode, :interest_rate,
                      :interest_period, :interest_basis)
      end

      def changed_fields
        fields = %i[amount date due_date status description interest_mode interest_rate]
        fields.filter_map do |f|
          next unless params[f].present?
          old = @loan.send(f)
          new = params[f]
          "#{f}: #{old} → #{new}" if old.to_s != new.to_s
        end
      end

      def serialize(l)
        {
          id:                  l.id.to_s,
          lender_user_id:      l.lender_user_id.to_s,
          borrower_user_id:    l.borrower_user_id&.to_s,
          contact_id:          l.contact_id.to_s,
          contact_name:        l.contact.name,
          direction:           l.lender_for?(current_user.id) ? "lent" : "borrowed",
          amount:              l.amount.to_f,
          date:                l.date.iso8601,
          due_date:            l.due_date&.iso8601,
          status:              l.status,
          confirmation_status: l.confirmation_status,
          interest_mode:       l.interest_mode,
          interest_rate:       l.interest_rate&.to_f,
          interest_period:     l.interest_period,
          interest_basis:      l.interest_basis,
          description:         l.description,
          category_id:         l.category_id&.to_s,
          category_name:       l.category&.name || "",
          created_at:          l.created_at.iso8601
        }
      end

      def serialize_logs(logs)
        logs.map { |l| { id: l.id.to_s, action: l.action, details: l.details, created_at: l.created_at.iso8601 } }
      end

      def serialize_comments(comments)
        comments.map { |c| serialize_comment(c) }
      end

      def serialize_comment(c)
        { id: c.id.to_s, user_id: c.user_id.to_s, text: c.text, created_at: c.created_at.iso8601 }
      end
    end
  end
end
```

- [ ] **Step 4: Add confirmation route**

In `rails_backend/config/routes.rb`, replace the loans resource block:

```ruby
resources :loans, only: [:create, :index, :show, :update, :destroy] do
  member do
    post  :comments
    patch :confirmation
  end
end
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd rails_backend && bin/rails test test/controllers/api/v1/loans_controller_test.rb -v
```

Expected: `13 runs, 13 assertions, 0 failures, 0 errors`

- [ ] **Step 6: Run the full test suite**

```bash
cd rails_backend && bin/rails test -v
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add rails_backend/app/controllers/api/v1/loans_controller.rb \
        rails_backend/config/routes.rb \
        rails_backend/test/controllers/api/v1/loans_controller_test.rb
git commit -m "feat: bilateral LoansController with access control and confirmation action"
```

---

## Part B: Flutter App

---

### Task 8: Contact Model + ContactsRepository

**Files:**
- Create: `square_app/lib/features/contacts/data/contact_model.dart`
- Create: `square_app/lib/features/contacts/data/contacts_repository.dart`

- [ ] **Step 1: Create Contact model**

Create `square_app/lib/features/contacts/data/contact_model.dart`:

```dart
class Contact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? linkedUserId;
  final bool onPlatform;
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.linkedUserId,
    required this.onPlatform,
    required this.createdAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'],
        email: json['email'],
        linkedUserId: json['linked_user_id'],
        onPlatform: json['on_platform'] ?? false,
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
      );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class PlatformUserResult {
  final String id;
  final String username;
  final String name;
  final String email;
  final String? mobileNumber;

  PlatformUserResult({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.mobileNumber,
  });

  factory PlatformUserResult.fromJson(Map<String, dynamic> json) =>
      PlatformUserResult(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        mobileNumber: json['mobile_number'],
      );
}

class ContactSearchResult {
  final List<Contact> contacts;
  final List<PlatformUserResult> platformUsers;

  ContactSearchResult({required this.contacts, required this.platformUsers});
}
```

- [ ] **Step 2: Create ContactsRepository**

Create `square_app/lib/features/contacts/data/contacts_repository.dart`:

```dart
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import 'contact_model.dart';
import '../../../transactions/data/loan_model.dart';

class ContactsRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<List<Contact>> getContacts(String token) async {
    final res = await _dio.get(
      '/contacts',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (res.data as List).map((j) => Contact.fromJson(j)).toList();
  }

  Future<ContactSearchResult> search(String token, String query) async {
    final res = await _dio.get(
      '/contacts/search',
      queryParameters: {'q': query},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = res.data as Map<String, dynamic>;
    return ContactSearchResult(
      contacts: (data['contacts'] as List? ?? [])
          .map((j) => Contact.fromJson(j))
          .toList(),
      platformUsers: (data['platform_users'] as List? ?? [])
          .map((j) => PlatformUserResult.fromJson(j))
          .toList(),
    );
  }

  Future<Contact> createContact(
    String token, {
    required String name,
    String? phone,
    String? email,
    String? linkedUserId,
  }) async {
    final res = await _dio.post(
      '/contacts',
      data: {
        'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (linkedUserId != null) 'linked_user_id': linkedUserId,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Contact.fromJson(res.data);
  }

  Future<Map<String, dynamic>> getContactLoans(
      String token, String contactId) async {
    final res = await _dio.get(
      '/contacts/$contactId/loans',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final data = res.data as Map<String, dynamic>;
    return {
      'contact': Contact.fromJson(data['contact']),
      'loans': (data['loans'] as List)
          .map((j) => Loan.fromJson(j))
          .toList(),
      'net_balance': data['net_balance'],
    };
  }
}
```

- [ ] **Step 3: Update Loan model to include new fields**

Replace `square_app/lib/features/transactions/data/loan_model.dart` with:

```dart
class Loan {
  final String id;
  final String lenderUserId;
  final String? borrowerUserId;
  final String contactId;
  final String contactName;
  final String direction; // 'lent' or 'borrowed'
  final double amount;
  final String status; // 'PENDING', 'PARTIAL', 'PAID'
  final String confirmationStatus; // 'pending', 'confirmed', 'disputed'
  final DateTime date;
  final DateTime? dueDate;
  final String interestMode; // 'none', 'from_start', 'penalty'
  final double? interestRate;
  final String? interestPeriod;
  final String? interestBasis;
  final String? description;
  final String categoryId;
  final String categoryName;
  final DateTime createdAt;

  Loan({
    required this.id,
    required this.lenderUserId,
    this.borrowerUserId,
    required this.contactId,
    required this.contactName,
    required this.direction,
    required this.amount,
    required this.status,
    required this.confirmationStatus,
    required this.date,
    this.dueDate,
    required this.interestMode,
    this.interestRate,
    this.interestPeriod,
    this.interestBasis,
    this.description,
    this.categoryId = '',
    this.categoryName = '',
    required this.createdAt,
  });

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        id: json['id'] ?? '',
        lenderUserId: json['lender_user_id'] ?? '',
        borrowerUserId: json['borrower_user_id'],
        contactId: json['contact_id'] ?? '',
        contactName: json['contact_name'] ?? '',
        direction: json['direction'] ?? 'lent',
        amount: (json['amount'] ?? 0).toDouble(),
        status: json['status'] ?? 'PENDING',
        confirmationStatus: json['confirmation_status'] ?? 'pending',
        date: DateTime.parse(
            json['date'] ?? DateTime.now().toIso8601String()),
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'])
            : null,
        interestMode: json['interest_mode'] ?? 'none',
        interestRate: json['interest_rate']?.toDouble(),
        interestPeriod: json['interest_period'],
        interestBasis: json['interest_basis'],
        description: json['description'],
        categoryId: json['category_id'] ?? '',
        categoryName: json['category_name'] ?? '',
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
      );

  bool get isPending => status == 'PENDING';
  bool get isPaid => status == 'PAID';
  bool get isPartial => status == 'PARTIAL';
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && !isPaid;
}
```

- [ ] **Step 4: Commit**

```bash
git add square_app/lib/features/contacts/data/ \
        square_app/lib/features/transactions/data/loan_model.dart
git commit -m "feat(flutter): Contact model, ContactsRepository, updated Loan model"
```

---

### Task 9: ContactsProvider + ContactsScreen

**Files:**
- Create: `square_app/lib/features/contacts/presentation/contacts_provider.dart`
- Create: `square_app/lib/features/contacts/presentation/screens/contacts_screen.dart`
- Create: `square_app/lib/features/contacts/presentation/screens/add_contact_screen.dart`

- [ ] **Step 1: Create ContactsProvider**

Create `square_app/lib/features/contacts/presentation/contacts_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/contact_model.dart';
import '../data/contacts_repository.dart';

final contactsRepositoryProvider = Provider((_) => ContactsRepository());

final contactsProvider =
    AsyncNotifierProvider<ContactsNotifier, List<Contact>>(
        ContactsNotifier.new);

class ContactsNotifier extends AsyncNotifier<List<Contact>> {
  @override
  Future<List<Contact>> build() => _fetch();

  Future<List<Contact>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return ref.read(contactsRepositoryProvider).getContacts(token);
  }

  Future<Contact> create({
    required String name,
    String? phone,
    String? email,
    String? linkedUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final contact = await ref.read(contactsRepositoryProvider).createContact(
          token,
          name: name,
          phone: phone,
          email: email,
          linkedUserId: linkedUserId,
        );
    state = AsyncData([...state.value ?? [], contact]);
    return contact;
  }
}

final contactSearchProvider = FutureProvider.family<ContactSearchResult, String>(
  (ref, query) async {
    if (query.length < 2) {
      return ContactSearchResult(contacts: [], platformUsers: []);
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return ref.read(contactsRepositoryProvider).search(token, query);
  },
);
```

- [ ] **Step 2: Create ContactsScreen**

Create `square_app/lib/features/contacts/presentation/screens/contacts_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../contacts_provider.dart';
import '../../data/contact_model.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
      appBar: AppBar(
        title: Text(
          'Contacts',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.userPlus,
                color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () => context.push('/contacts/add'),
          ),
        ],
      ),
      body: contacts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? _buildEmpty(context, isDark)
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    _ContactTile(contact: list[i], isDark: isDark),
              ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.users,
              size: 48,
              color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 12),
          Text('No contacts yet',
              style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push('/contacts/add'),
            child: const Text('Add first contact'),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final bool isDark;

  const _ContactTile({required this.contact, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isDark ? AppColors.slate[700] : AppColors.slate[200],
        child: Text(
          contact.initials,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      title: Text(
        contact.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: contact.onPlatform
          ? Text('On platform',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[600]))
          : Text(contact.phone ?? contact.email ?? '',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38)),
      trailing: Icon(LucideIcons.chevronRight,
          size: 16,
          color: isDark ? Colors.white24 : Colors.black26),
      onTap: () => context.push('/contacts/${contact.id}'),
    );
  }
}
```

- [ ] **Step 3: Create AddContactScreen**

Create `square_app/lib/features/contacts/presentation/screens/add_contact_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../contacts_provider.dart';
import '../../data/contact_model.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedLinkedUserId;
  bool _isLoading = false;
  bool _showManualForm = false;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final contact = await ref.read(contactsProvider.notifier).create(
            name: _nameController.text,
            phone: _phoneController.text.isEmpty ? null : _phoneController.text,
            email: _emailController.text.isEmpty ? null : _emailController.text,
            linkedUserId: _selectedLinkedUserId,
          );
      if (mounted) context.pop(contact); // return Contact so loan screen can capture it
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchResult =
        ref.watch(contactSearchProvider(_searchController.text));

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
      appBar: AppBar(
        title: Text('Add Contact',
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.x,
              color: isDark ? Colors.white70 : Colors.black54),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_showManualForm)
            TextButton(
              onPressed: _isLoading ? null : _saveContact,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or email...',
                prefixIcon: const Icon(LucideIcons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            if (_searchController.text.length >= 2)
              searchResult.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (result) => _buildSearchResults(result, isDark),
              )
            else if (_showManualForm)
              _buildManualForm(isDark)
            else
              TextButton.icon(
                onPressed: () => setState(() => _showManualForm = true),
                icon: const Icon(LucideIcons.userPlus),
                label: const Text('Add manually'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(ContactSearchResult result, bool isDark) {
    return Expanded(
      child: ListView(
        children: [
          if (result.contacts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('YOUR CONTACTS',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            ...result.contacts.map((c) => _buildContactTile(
                c.name, c.phone ?? c.email ?? '', null, isDark,
                onTap: () => context.pop(c))),
          ],
          if (result.platformUsers.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('ON PLATFORM',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            ...result.platformUsers.map((u) => _buildContactTile(
                u.name, u.email, Colors.green[600], isDark,
                onTap: () async {
                  _nameController.text = u.name;
                  _emailController.text = u.email;
                  _phoneController.text = u.mobileNumber ?? '';
                  setState(() {
                    _selectedLinkedUserId = u.id;
                    _showManualForm = true;
                  });
                  await _saveContact();
                })),
          ],
          if (result.contacts.isEmpty && result.platformUsers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  Text('No results for "${_searchController.text}"',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      _nameController.text = _searchController.text;
                      setState(() => _showManualForm = true);
                    },
                    child: Text('Add "${_searchController.text}" manually'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildManualForm(bool isDark) {
    return Expanded(
      child: ListView(
        children: [
          _field(_nameController, 'Name *', LucideIcons.user, isDark),
          const SizedBox(height: 12),
          _field(_phoneController, 'Phone (optional)', LucideIcons.phone,
              isDark),
          const SizedBox(height: 12),
          _field(
              _emailController, 'Email (optional)', LucideIcons.mail, isDark),
        ],
      ),
    );
  }

  Widget _buildContactTile(
      String name, String sub, Color? subColor, bool isDark,
      {required VoidCallback onTap}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDark ? AppColors.slate[700] : AppColors.slate[200],
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      title: Text(name),
      subtitle: Text(sub,
          style: TextStyle(fontSize: 12, color: subColor ?? Colors.grey)),
      onTap: onTap,
    );
  }

  Widget _field(
      TextEditingController ctrl, String hint, IconData icon, bool isDark) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add square_app/lib/features/contacts/presentation/
git commit -m "feat(flutter): ContactsProvider, ContactsScreen, AddContactScreen"
```

---

### Task 10: ContactDetailScreen (Counterparty Screen)

**Files:**
- Create: `square_app/lib/features/contacts/presentation/screens/contact_detail_screen.dart`

- [ ] **Step 1: Create ContactDetailScreen**

Create `square_app/lib/features/contacts/presentation/screens/contact_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../data/contact_model.dart';
import '../../data/contacts_repository.dart';
import '../../../transactions/data/loan_model.dart';

final _contactLoansProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, contactId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return ContactsRepository().getContactLoans(token, contactId);
  },
);

class ContactDetailScreen extends ConsumerWidget {
  final String contactId;

  const ContactDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_contactLoansProvider(contactId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (d) => _buildBody(context, ref, d, isDark),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref,
      Map<String, dynamic> data, bool isDark) {
    final contact = data['contact'] as Contact;
    final loans = data['loans'] as List<Loan>;
    final net = data['net_balance'] as Map<String, dynamic>;
    final activeLoans =
        loans.where((l) => l.status != 'PAID').toList();
    final settledLoans =
        loans.where((l) => l.status == 'PAID').toList();

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft,
                  color: isDark ? Colors.white : Colors.black),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(contact, net, isDark),
            ),
            bottom: TabBar(
              labelColor: isDark ? Colors.white : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor:
                  isDark ? Colors.white : Colors.black,
              tabs: [
                Tab(text: 'Active (${activeLoans.length})'),
                Tab(text: 'Settled (${settledLoans.length})'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _LoanList(loans: activeLoans, isDark: isDark),
            _LoanList(loans: settledLoans, isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      Contact contact, Map<String, dynamic> net, bool isDark) {
    final isOwed = net['direction'] == 'owed_to_you';
    final amount = (net['amount'] as num).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark
                    ? AppColors.slate[700]
                    : AppColors.slate[200],
                child: Text(
                  contact.initials,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              isDark ? Colors.white : Colors.black)),
                  if (contact.phone != null)
                    Text(contact.phone!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  if (contact.onPlatform)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('On platform ✓',
                          style: TextStyle(
                              fontSize: 10, color: Colors.green)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isOwed
                  ? Colors.green.withOpacity(0.12)
                  : Colors.red.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOwed
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwed
                      ? '${contact.name} owes you'
                      : 'You owe ${contact.name}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
                Text(
                  CurrencyFormatter.format(amount),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isOwed ? Colors.green[600] : Colors.red[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanList extends StatelessWidget {
  final List<Loan> loans;
  final bool isDark;

  const _LoanList({required this.loans, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Center(
        child: Text('None',
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: loans.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => _LoanTile(loan: loans[i], isDark: isDark),
    );
  }
}

class _LoanTile extends StatelessWidget {
  final Loan loan;
  final bool isDark;

  const _LoanTile({required this.loan, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLent = loan.direction == 'lent';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: loan.isOverdue
              ? Colors.red[400]
              : loan.isPaid
                  ? Colors.green[600]
                  : Colors.amber[600],
        ),
      ),
      title: Text(
        loan.description ?? (isLent ? 'Lent' : 'Borrowed'),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        loan.dueDate != null
            ? 'Due ${loan.dueDate!.day}/${loan.dueDate!.month}/${loan.dueDate!.year}'
            : 'No due date',
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.format(loan.amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isLent ? Colors.green[600] : Colors.red[400],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: loan.isOverdue
                  ? Colors.red.withOpacity(0.12)
                  : loan.isPaid
                      ? Colors.green.withOpacity(0.12)
                      : Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              loan.isOverdue ? 'Overdue' : loan.status,
              style: TextStyle(
                fontSize: 9,
                color: loan.isOverdue
                    ? Colors.red[400]
                    : loan.isPaid
                        ? Colors.green[600]
                        : Colors.amber[600],
              ),
            ),
          ),
        ],
      ),
      onTap: () => context.push('/loans/${loan.id}'),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add square_app/lib/features/contacts/presentation/screens/contact_detail_screen.dart
git commit -m "feat(flutter): ContactDetailScreen (counterparty screen with net balance)"
```

---

### Task 11: Update AddEditLoanScreen — Contact Picker

**Files:**
- Modify: `square_app/lib/features/transactions/presentation/screens/add_edit_loan_screen.dart`
- Modify: `square_app/lib/core/router.dart`

- [ ] **Step 1: Update AddEditLoanScreen**

Replace `square_app/lib/features/transactions/presentation/screens/add_edit_loan_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/category_picker_sheet.dart';
import '../../../contacts/data/contact_model.dart';
import '../../../transactions/presentation/transactions_provider.dart';

class AddEditLoanScreen extends ConsumerStatefulWidget {
  const AddEditLoanScreen({super.key});

  @override
  ConsumerState<AddEditLoanScreen> createState() => _AddEditLoanScreenState();
}

class _AddEditLoanScreenState extends ConsumerState<AddEditLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Contact? _selectedContact;
  String _interestMode = 'none';
  DateTime _selectedDate = DateTime.now();
  DateTime? _dueDate;
  bool _isLoading = false;
  String? _selectedCategoryId;
  String _selectedCategoryName = 'Category';

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    final result = await context.push<Contact>('/contacts/add');
    if (result != null) setState(() => _selectedContact = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a contact')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = {
        'contact_id': _selectedContact!.id,
        'amount': double.parse(_amountController.text),
        'date': _selectedDate.toUtc().toIso8601String(),
        'interest_mode': _interestMode,
        'description': _descriptionController.text,
        'category_id': _selectedCategoryId ?? '',
        if (_dueDate != null) 'due_date': _dueDate!.toUtc().toIso8601String(),
      };
      await ref.read(loansProvider.notifier).create(data);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loan added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
      appBar: AppBar(
        title: Text('Add Loan',
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.x,
              color: isDark ? Colors.white70 : Colors.black54),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Contact picker
                GestureDetector(
                  onTap: _pickContact,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.slate[900]
                          : AppColors.slate[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.user,
                            size: 20,
                            color: isDark ? Colors.white54 : Colors.black38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedContact?.name ?? 'Select contact',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedContact != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _selectedContact != null
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : (isDark
                                        ? AppColors.slate[500]
                                        : AppColors.slate[400])),
                          ),
                        ),
                        Icon(LucideIcons.chevronRight,
                            size: 16,
                            color:
                                isDark ? Colors.white24 : Colors.black26),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Amount
                _buildFieldRow(
                  icon: LucideIcons.indianRupee,
                  iconColor: isDark
                      ? AppColors.slate[400]!
                      : AppColors.slate[600]!,
                  isDark: isDark,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.slate[500]
                              : AppColors.slate[400]),
                      border: InputBorder.none,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                    color:
                        isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                const SizedBox(height: 12),
                // Interest mode
                _buildInterestModeSelector(isDark),
                const SizedBox(height: 12),
                Divider(
                    color:
                        isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                const SizedBox(height: 12),
                // Description
                _buildFieldRow(
                  icon: LucideIcons.fileText,
                  iconColor:
                      isDark ? Colors.white54 : Colors.black38,
                  isDark: isDark,
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: null,
                    minLines: 2,
                    style: TextStyle(
                        fontSize: 14,
                        color:
                            isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Description (optional)',
                      hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.slate[500]
                              : AppColors.slate[400],
                          fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 180),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: _buildFloatingDock(isDark),
    );
  }

  Widget _buildInterestModeSelector(bool isDark) {
    final modes = [
      ('none', 'No interest'),
      ('from_start', 'Interest from start'),
      ('penalty', 'Penalty after due date'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Interest',
            style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 0.06)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: modes
              .map((m) => ChoiceChip(
                    label: Text(m.$2,
                        style: const TextStyle(fontSize: 12)),
                    selected: _interestMode == m.$1,
                    onSelected: (_) =>
                        setState(() => _interestMode = m.$1),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFieldRow(
      {required IconData icon,
      required Color iconColor,
      required Widget child,
      required bool isDark}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildFloatingDock(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildDockItem(
            LucideIcons.calendar,
            DateFormat('MMM dd').format(_selectedDate),
            isDark,
            () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100));
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          _buildDockItem(
            LucideIcons.calendarClock,
            _dueDate != null
                ? 'Due ${DateFormat('MMM dd').format(_dueDate!)}'
                : 'Due date',
            isDark,
            () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100));
              if (picked != null) setState(() => _dueDate = picked);
            },
          ),
          _buildDockItem(
            LucideIcons.tag,
            _selectedCategoryName,
            isDark,
            () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CategoryPickerSheet(
                selectedId: _selectedCategoryId,
                appliesTo: 'loan',
                onSelected: (id, name) => setState(() {
                  _selectedCategoryId = id;
                  _selectedCategoryName = name;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockItem(
      IconData icon, String label, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color:
                      isDark ? Colors.white54 : Colors.black54),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add routes for contacts screens**

In `square_app/lib/core/router.dart`, add routes for contacts. Open the file and add alongside existing routes:

```dart
GoRoute(
  path: '/contacts',
  builder: (_, __) => const ContactsScreen(),
),
GoRoute(
  path: '/contacts/add',
  builder: (_, __) => const AddContactScreen(),
),
GoRoute(
  path: '/contacts/:id',
  builder: (_, state) =>
      ContactDetailScreen(contactId: state.pathParameters['id']!),
),
```

Add the necessary imports at the top of `router.dart`:

```dart
import '../features/contacts/presentation/screens/contacts_screen.dart';
import '../features/contacts/presentation/screens/add_contact_screen.dart';
import '../features/contacts/presentation/screens/contact_detail_screen.dart';
```

- [ ] **Step 3: Run Flutter build to verify no compile errors**

```bash
cd square_app && flutter build ios --simulator --no-codesign 2>&1 | tail -20
```

Expected: `Build complete.` with no errors.

- [ ] **Step 4: Commit**

```bash
git add square_app/lib/features/transactions/presentation/screens/add_edit_loan_screen.dart \
        square_app/lib/core/router.dart
git commit -m "feat(flutter): update AddEditLoanScreen with contact picker + interest mode selector"
```

---

## Plan 2 Preview

**2026-05-24-loan-module-plan-2-interest-payments.md** will cover:
- `InterestCalculator` Ruby service (on-demand calculation, all 3 modes)
- `loan_payments` table + `LoanPaymentsController`
- `RecordPaymentSheet` Flutter widget + interest-to-income popup
- `LoanDetailScreen` with payment history + interest timeline

## Plan 3 Preview

**2026-05-24-loan-module-plan-3-reminders.md** will cover:
- `loan_reminders` table + `LoanRemindersController`
- Notification delivery service (push/SMS/email)
- `ReminderSheet` Flutter widget
- Auto-notifications on loan create/payment/settlement
