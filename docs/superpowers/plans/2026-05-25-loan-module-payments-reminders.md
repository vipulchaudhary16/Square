# Loan Module: Payments & Reminders Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the bilateral loan module by implementing payment recording, interest calculation, reminder storage, and the Flutter `LoanDetailScreen` — finishing the spec at `docs/superpowers/specs/2026-05-24-loan-module-design.md` (sections 3, 4, 6, 7, 8).

**Architecture:** A pure `InterestCalculatorService` computes all interest on demand. `LoanPaymentsController` and `LoanRemindersController` handle nested loan resources. The loans `show` endpoint is enriched with payments + interest data. Flutter `LoanDetailScreen` uses a `FutureProvider.family` that calls an enriched `GET /api/loans/:id` endpoint, and hosts `RecordPaymentSheet` and `ReminderSheet` modals.

**Tech Stack:** Rails 7.2, minitest + factory_bot, Flutter/Dart 3, Riverpod, GoRouter, Dio, lucide_icons, intl

---

## File Map

**Create:**
- `rails_backend/db/migrate/<ts>_create_loan_payments.rb`
- `rails_backend/db/migrate/<ts>_create_loan_reminders.rb`
- `rails_backend/app/models/loan_payment.rb`
- `rails_backend/app/models/loan_reminder.rb`
- `rails_backend/app/services/interest_calculator_service.rb`
- `rails_backend/app/controllers/api/v1/loan_payments_controller.rb`
- `rails_backend/app/controllers/api/v1/loan_reminders_controller.rb`
- `rails_backend/test/models/loan_payment_test.rb`
- `rails_backend/test/services/interest_calculator_service_test.rb`
- `rails_backend/test/controllers/api/v1/loan_payments_controller_test.rb`
- `rails_backend/test/controllers/api/v1/loan_reminders_controller_test.rb`
- `rails_backend/test/factories/loan_payments.rb`
- `square_app/lib/features/transactions/data/loan_payment_model.dart`
- `square_app/lib/features/loans/data/loans_repository.dart`
- `square_app/lib/features/loans/presentation/loan_detail_screen.dart`
- `square_app/lib/features/loans/presentation/widgets/record_payment_sheet.dart`
- `square_app/lib/features/loans/presentation/widgets/interest_timeline_card.dart`
- `square_app/lib/features/loans/presentation/widgets/reminder_sheet.dart`
- `square_app/test/features/loans/loan_payment_model_test.dart`

**Modify:**
- `rails_backend/app/models/loan.rb` — add `has_many :loan_payments`
- `rails_backend/app/controllers/api/v1/loans_controller.rb` — add computed fields to `serialize`, enrich `show`
- `rails_backend/config/routes.rb` — add payment + reminder member routes
- `square_app/lib/features/transactions/data/loan_model.dart` — add `outstanding`, `accrued_interest`, `total_due`
- `square_app/lib/core/router.dart` — replace `/loans/:id` placeholder with `LoanDetailScreen`
- `square_app/lib/features/transactions/presentation/transactions_screen.dart` — loan tile `onTap`

---

## Task 1: Create `loan_payments` table, model, and factory

**Files:**
- Create: `rails_backend/db/migrate/<ts>_create_loan_payments.rb`
- Create: `rails_backend/app/models/loan_payment.rb`
- Create: `rails_backend/test/factories/loan_payments.rb`
- Modify: `rails_backend/app/models/loan.rb`

- [ ] **Step 1.1: Generate migration**

```bash
cd rails_backend
bin/rails generate migration CreateLoanPayments
```

- [ ] **Step 1.2: Fill in the migration**

Open the generated file (e.g. `db/migrate/20260525XXXXXX_create_loan_payments.rb`) and replace the body:

```ruby
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
```

- [ ] **Step 1.3: Run migration**

```bash
bin/rails db:migrate
```

Expected: `CreateLoanPayments: migrated` with no errors.

- [ ] **Step 1.4: Write model**

Create `rails_backend/app/models/loan_payment.rb`:

```ruby
class LoanPayment < ApplicationRecord
  belongs_to :loan

  validates :loan_id, :amount, :paid_at, presence: true
  validates :amount, numericality: { greater_than: 0 }
end
```

- [ ] **Step 1.5: Add association to Loan**

In `rails_backend/app/models/loan.rb`, add after the existing `has_many :comments` line:

```ruby
has_many :loan_payments, dependent: :destroy
```

- [ ] **Step 1.6: Write factory**

Create `rails_backend/test/factories/loan_payments.rb`:

```ruby
FactoryBot.define do
  factory :loan_payment do
    association :loan
    amount  { 1000.00 }
    paid_at { Time.current }
    note    { nil }
  end
end
```

- [ ] **Step 1.7: Write model tests**

Create `rails_backend/test/models/loan_payment_test.rb`:

```ruby
require "test_helper"

class LoanPaymentTest < ActiveSupport::TestCase
  setup do
    @lender  = create(:user)
    @contact = create(:contact, owner: @lender)
    @loan    = create(:loan, lender: @lender, contact: @contact, amount: 5000)
  end

  test "valid payment saves" do
    payment = LoanPayment.new(loan: @loan, amount: 1000, paid_at: Time.current)
    assert payment.valid?
  end

  test "requires amount" do
    payment = LoanPayment.new(loan: @loan, paid_at: Time.current)
    assert_not payment.valid?
    assert_includes payment.errors[:amount], "can't be blank"
  end

  test "requires paid_at" do
    payment = LoanPayment.new(loan: @loan, amount: 1000)
    assert_not payment.valid?
    assert_includes payment.errors[:paid_at], "can't be blank"
  end

  test "amount must be positive" do
    payment = LoanPayment.new(loan: @loan, amount: 0, paid_at: Time.current)
    assert_not payment.valid?
    assert_includes payment.errors[:amount], "must be greater than 0"
  end

  test "belongs to loan" do
    payment = create(:loan_payment, loan: @loan, amount: 500)
    assert_equal @loan, payment.loan
    assert_includes @loan.loan_payments, payment
  end
end
```

- [ ] **Step 1.8: Run tests**

```bash
bin/rails test test/models/loan_payment_test.rb
```

Expected: 5 tests, 0 failures.

- [ ] **Step 1.9: Commit**

```bash
git add db/migrate db/schema.rb app/models/loan_payment.rb app/models/loan.rb \
        test/models/loan_payment_test.rb test/factories/loan_payments.rb
git commit -m "feat(rails): loan_payments table, model, and factory"
```

---

## Task 2: Create `loan_reminders` table and model

**Files:**
- Create: `rails_backend/db/migrate/<ts>_create_loan_reminders.rb`
- Create: `rails_backend/app/models/loan_reminder.rb`

- [ ] **Step 2.1: Generate migration**

```bash
bin/rails generate migration CreateLoanReminders
```

- [ ] **Step 2.2: Fill in migration**

```ruby
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
```

- [ ] **Step 2.3: Run migration**

```bash
bin/rails db:migrate
```

Expected: `CreateLoanReminders: migrated`.

- [ ] **Step 2.4: Write model**

Create `rails_backend/app/models/loan_reminder.rb`:

```ruby
class LoanReminder < ApplicationRecord
  belongs_to :loan
  belongs_to :set_by_user, class_name: "User"

  validates :loan_id, :set_by_user_id, :remind_at, presence: true
end
```

- [ ] **Step 2.5: Add association to Loan**

In `rails_backend/app/models/loan.rb`, add after `has_many :loan_payments`:

```ruby
has_many :loan_reminders, dependent: :destroy
```

- [ ] **Step 2.6: Commit**

```bash
git add db/migrate db/schema.rb app/models/loan_reminder.rb app/models/loan.rb
git commit -m "feat(rails): loan_reminders table and model"
```

---

## Task 3: InterestCalculatorService

**Files:**
- Create: `rails_backend/app/services/interest_calculator_service.rb`
- Create: `rails_backend/test/services/interest_calculator_service_test.rb`

- [ ] **Step 3.1: Write failing tests first**

Create `rails_backend/test/services/interest_calculator_service_test.rb`:

```ruby
require "test_helper"

class InterestCalculatorServiceTest < ActiveSupport::TestCase
  def build_loan(overrides = {})
    lender  = create(:user)
    contact = create(:contact, owner: lender)
    create(:loan, { lender: lender, contact: contact,
                    amount: 10_000, date: 10.days.ago,
                    status: "PENDING", interest_mode: "none" }.merge(overrides))
  end

  # --- none mode ---

  test "mode none: outstanding = amount, zero interest" do
    loan   = build_loan(amount: 5000, interest_mode: "none")
    result = InterestCalculatorService.new(loan).call
    assert_equal 5000.0,  result[:outstanding]
    assert_equal 0.0,     result[:accrued_interest]
    assert_equal 5000.0,  result[:total_due]
    assert_equal 0.0,     result[:daily_rate]
    assert_empty          result[:interest_timeline]
  end

  test "mode none: payment reduces outstanding" do
    loan = build_loan(amount: 5000, interest_mode: "none")
    create(:loan_payment, loan: loan, amount: 2000)
    result = InterestCalculatorService.new(loan).call
    assert_equal 3000.0, result[:outstanding]
    assert_equal 3000.0, result[:total_due]
  end

  # --- from_start + principal basis ---

  test "mode from_start principal: accrued_interest = outstanding * daily_rate * days" do
    loan = build_loan(
      amount: 10_000, date: 10.days.ago,
      interest_mode: "from_start",
      interest_rate: 0.01, interest_period: "daily", interest_basis: "principal"
    )
    result = InterestCalculatorService.new(loan).call
    assert_equal 10_000.0, result[:outstanding]
    assert_in_delta 1000.0, result[:accrued_interest], 0.01
    assert_in_delta 11_000.0, result[:total_due], 0.01
    assert_equal 0.01, result[:daily_rate]
    assert_equal 10, result[:interest_timeline].length
  end

  test "mode from_start principal: monthly rate normalised to daily" do
    loan = build_loan(
      amount: 30_000, date: 30.days.ago,
      interest_mode: "from_start",
      interest_rate: 0.03, interest_period: "monthly", interest_basis: "principal"
    )
    result = InterestCalculatorService.new(loan).call
    expected_daily_rate = 0.03 / 30.0
    assert_in_delta expected_daily_rate, result[:daily_rate], 0.000001
    expected_interest = 30_000 * expected_daily_rate * 30
    assert_in_delta expected_interest, result[:accrued_interest], 0.01
  end

  test "mode from_start principal: annual rate normalised to daily" do
    loan = build_loan(
      amount: 36_500, date: 365.days.ago,
      interest_mode: "from_start",
      interest_rate: 0.365, interest_period: "annual", interest_basis: "principal"
    )
    result = InterestCalculatorService.new(loan).call
    expected_daily_rate = 0.365 / 365.0
    assert_in_delta expected_daily_rate, result[:daily_rate], 0.000001
    expected_interest = 36_500 * expected_daily_rate * 365
    assert_in_delta expected_interest, result[:accrued_interest], 0.01
  end

  # --- from_start + total (compound) basis ---

  test "mode from_start total: compound interest formula" do
    loan = build_loan(
      amount: 10_000, date: 10.days.ago,
      interest_mode: "from_start",
      interest_rate: 0.01, interest_period: "daily", interest_basis: "total"
    )
    result = InterestCalculatorService.new(loan).call
    expected = 10_000 * ((1.01**10) - 1)
    assert_in_delta expected, result[:accrued_interest], 0.01
  end

  # --- penalty mode ---

  test "penalty mode: zero interest when not overdue" do
    loan = build_loan(
      amount: 5000, date: 10.days.ago,
      interest_mode: "penalty", due_date: 3.days.from_now,
      interest_rate: 0.02, interest_period: "daily", interest_basis: "principal"
    )
    result = InterestCalculatorService.new(loan).call
    assert_equal 0.0, result[:accrued_interest]
    assert_empty result[:interest_timeline]
  end

  test "penalty mode: interest accrues after due_date" do
    loan = build_loan(
      amount: 5000, date: 20.days.ago,
      interest_mode: "penalty", due_date: 10.days.ago,
      interest_rate: 0.02, interest_period: "daily", interest_basis: "principal"
    )
    result = InterestCalculatorService.new(loan).call
    assert_in_delta 5000 * 0.02 * 10, result[:accrued_interest], 0.01
    assert_equal 10, result[:interest_timeline].length
  end

  # --- timeline structure ---

  test "timeline entries have date, daily_interest, cumulative" do
    loan = build_loan(
      amount: 1000, date: 3.days.ago,
      interest_mode: "from_start",
      interest_rate: 0.01, interest_period: "daily", interest_basis: "principal"
    )
    result  = InterestCalculatorService.new(loan).call
    entries = result[:interest_timeline]
    assert_equal 3, entries.length
    assert_respond_to entries.first, :[]
    assert entries.first[:date].is_a?(String)
    assert entries.first[:daily_interest] > 0
    assert_in_delta entries.last[:cumulative], result[:accrued_interest], 0.01
  end
end
```

- [ ] **Step 3.2: Run tests — verify they all fail**

```bash
mkdir -p test/services
bin/rails test test/services/interest_calculator_service_test.rb
```

Expected: errors loading constant `InterestCalculatorService`.

- [ ] **Step 3.3: Implement the service**

Create `rails_backend/app/services/interest_calculator_service.rb`:

```ruby
class InterestCalculatorService
  def initialize(loan)
    @loan = loan
  end

  def call
    outstanding = (@loan.amount - @loan.loan_payments.sum(:amount)).to_f
    return base_result(outstanding) if @loan.interest_mode == "none"

    daily_rate = normalize_rate
    days       = applicable_days

    interest = calculate_interest(outstanding, daily_rate, days)

    {
      outstanding:       outstanding.round(2),
      accrued_interest:  interest.round(2),
      total_due:         (outstanding + interest).round(2),
      daily_rate:        daily_rate.round(8),
      interest_timeline: build_timeline(outstanding, daily_rate, days)
    }
  end

  private

  def base_result(outstanding)
    { outstanding: outstanding.round(2), accrued_interest: 0.0,
      total_due: outstanding.round(2), daily_rate: 0.0, interest_timeline: [] }
  end

  def normalize_rate
    rate = (@loan.interest_rate || 0).to_f
    case @loan.interest_period
    when "monthly" then rate / 30
    when "annual"  then rate / 365
    else rate
    end
  end

  def applicable_days
    today = Date.today
    if @loan.interest_mode == "from_start"
      (today - @loan.date.to_date).to_i
    else
      [(today - @loan.due_date.to_date).to_i, 0].max
    end
  end

  def calculate_interest(outstanding, daily_rate, days)
    return 0.0 if days <= 0 || daily_rate <= 0
    if @loan.interest_basis == "total"
      outstanding * ((1 + daily_rate)**days - 1)
    else
      outstanding * daily_rate * days
    end
  end

  def build_timeline(outstanding, daily_rate, days)
    return [] if days <= 0 || daily_rate <= 0

    start_date = if @loan.interest_mode == "from_start"
      @loan.date.to_date + 1
    else
      @loan.due_date.to_date + 1
    end

    cumulative = 0.0
    (0...days).map do |i|
      daily = if @loan.interest_basis == "total"
        outstanding * daily_rate * (1 + daily_rate)**i
      else
        outstanding * daily_rate
      end
      cumulative += daily
      {
        date:           (start_date + i).iso8601,
        daily_interest: daily.round(2),
        cumulative:     cumulative.round(2)
      }
    end
  end
end
```

- [ ] **Step 3.4: Run tests — verify they pass**

```bash
bin/rails test test/services/interest_calculator_service_test.rb
```

Expected: 10 tests, 0 failures.

- [ ] **Step 3.5: Commit**

```bash
git add app/services/interest_calculator_service.rb \
        test/services/interest_calculator_service_test.rb
git commit -m "feat(rails): InterestCalculatorService with mode/basis/period support"
```

---

## Task 4: Enrich LoansController with computed fields

**Files:**
- Modify: `rails_backend/app/controllers/api/v1/loans_controller.rb`

The `serialize` method gets `outstanding`, `accrued_interest`, `total_due` from the calculator. The `show` action gets a `payments` array and `interest_timeline`.

- [ ] **Step 4.1: Write failing test for computed fields in show**

Append to `rails_backend/test/controllers/api/v1/loans_controller_test.rb` (find the end of the file and add):

```ruby
  # --- interest fields in show ---

  test "show includes outstanding, accrued_interest, total_due in loan object" do
    get "/api/loans/#{@loan.id}", headers: auth_header(@lender)
    assert_response :ok
    loan_json = JSON.parse(response.body)["loan"]
    assert loan_json.key?("outstanding")
    assert loan_json.key?("accrued_interest")
    assert loan_json.key?("total_due")
    assert_equal @loan.amount.to_f, loan_json["outstanding"]
    assert_equal 0.0, loan_json["accrued_interest"]
  end

  test "show includes payments array" do
    create(:loan_payment, loan: @loan, amount: 1000)
    get "/api/loans/#{@loan.id}", headers: auth_header(@lender)
    assert_response :ok
    body = JSON.parse(response.body)
    assert body.key?("payments")
    assert_equal 1, body["payments"].length
    assert_equal 1000.0, body["payments"].first["amount"]
  end

  test "index includes outstanding in each loan" do
    get "/api/loans", headers: auth_header(@lender)
    assert_response :ok
    first = JSON.parse(response.body).first
    assert first.key?("outstanding")
    assert first.key?("accrued_interest")
    assert first.key?("total_due")
  end
```

- [ ] **Step 4.2: Run the new tests — verify they fail**

```bash
bin/rails test test/controllers/api/v1/loans_controller_test.rb -n "/computed|outstanding|payments array|interest fields/"
```

Expected: failures for missing keys.

- [ ] **Step 4.3: Update LoansController**

In `rails_backend/app/controllers/api/v1/loans_controller.rb`:

Replace the `show` action:

```ruby
def show
  calc     = InterestCalculatorService.new(@loan).call
  logs     = @loan.activity_logs.includes(:user).order(created_at: :desc)
  comments = @loan.comments.includes(:user).order(created_at: :asc)
  render json: {
    loan:              serialize(@loan, calc),
    payments:          serialize_payments(@loan.loan_payments.order(paid_at: :desc)),
    interest_timeline: calc[:interest_timeline],
    logs:              serialize_logs(logs),
    comments:          serialize_comments(comments)
  }
end
```

Replace the `index` action:

```ruby
def index
  loans = Loan.for_user(current_user.id)
              .includes(:contact, :category, :loan_payments)
              .order(date: :desc)
  render json: loans.map { |l| serialize(l, InterestCalculatorService.new(l).call) }
end
```

Replace the `serialize` private method signature and body:

```ruby
def serialize(l, calc = nil)
  calc ||= InterestCalculatorService.new(l).call
  {
    id:                  l.id.to_s,
    lender_user_id:      l.lender_user_id.to_s,
    borrower_user_id:    l.borrower_user_id&.to_s,
    contact_id:          l.contact_id.to_s,
    contact_name:        l.contact&.name || "",
    direction:           l.lender_for?(current_user.id) ? "lent" : "borrowed",
    amount:              l.amount.to_f,
    outstanding:         calc[:outstanding],
    accrued_interest:    calc[:accrued_interest],
    total_due:           calc[:total_due],
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
```

Add a new private method `serialize_payments`:

```ruby
def serialize_payments(payments)
  payments.map do |p|
    {
      id:         p.id.to_s,
      loan_id:    p.loan_id.to_s,
      amount:     p.amount.to_f,
      paid_at:    p.paid_at.iso8601,
      note:       p.note,
      created_at: p.created_at.iso8601
    }
  end
end
```

- [ ] **Step 4.4: Run all loans controller tests**

```bash
bin/rails test test/controllers/api/v1/loans_controller_test.rb
```

Expected: all tests pass, 0 failures.

- [ ] **Step 4.5: Commit**

```bash
git add app/controllers/api/v1/loans_controller.rb \
        test/controllers/api/v1/loans_controller_test.rb
git commit -m "feat(rails): enrich loans show/index with computed interest + payments"
```

---

## Task 5: LoanPaymentsController (GET + POST) + routes

**Files:**
- Create: `rails_backend/app/controllers/api/v1/loan_payments_controller.rb`
- Create: `rails_backend/test/controllers/api/v1/loan_payments_controller_test.rb`
- Modify: `rails_backend/config/routes.rb`

- [ ] **Step 5.1: Write failing tests**

Create `rails_backend/test/controllers/api/v1/loan_payments_controller_test.rb`:

```ruby
require "test_helper"

class Api::V1::LoanPaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lender   = create(:user)
    @borrower = create(:user)
    @contact  = create(:contact, owner: @lender, linked_user: @borrower)
    @loan     = create(:loan, lender: @lender, borrower: @borrower,
                              contact: @contact, amount: 5000,
                              status: "PENDING", interest_mode: "none")
  end

  # --- GET index ---

  test "lender can list payments" do
    create(:loan_payment, loan: @loan, amount: 1000)
    get "/api/loans/#{@loan.id}/payments", headers: auth_header(@lender)
    assert_response :ok
    assert_equal 1, JSON.parse(response.body).length
  end

  test "borrower can list payments" do
    create(:loan_payment, loan: @loan, amount: 1000)
    get "/api/loans/#{@loan.id}/payments", headers: auth_header(@borrower)
    assert_response :ok
  end

  test "unrelated user cannot see payments" do
    get "/api/loans/#{@loan.id}/payments", headers: auth_header(create(:user))
    assert_response :not_found
  end

  # --- POST create ---

  test "lender can record a partial payment" do
    post "/api/loans/#{@loan.id}/payments",
         params: { amount: 2000, paid_at: Date.today.iso8601 }.to_json,
         headers: auth_header(@lender)
    assert_response :created
    @loan.reload
    assert_equal "PARTIAL", @loan.status
    assert_equal 1, @loan.loan_payments.count
  end

  test "recording full amount sets status to PAID" do
    post "/api/loans/#{@loan.id}/payments",
         params: { amount: 5000, paid_at: Date.today.iso8601 }.to_json,
         headers: auth_header(@lender)
    assert_response :created
    assert_equal "PAID", @loan.reload.status
  end

  test "recording payment that exactly clears outstanding sets PAID" do
    create(:loan_payment, loan: @loan, amount: 3000)
    post "/api/loans/#{@loan.id}/payments",
         params: { amount: 2000, paid_at: Date.today.iso8601 }.to_json,
         headers: auth_header(@lender)
    assert_response :created
    assert_equal "PAID", @loan.reload.status
  end

  test "borrower cannot record payment" do
    post "/api/loans/#{@loan.id}/payments",
         params: { amount: 1000, paid_at: Date.today.iso8601 }.to_json,
         headers: auth_header(@borrower)
    assert_response :forbidden
  end

  test "add_interest_to_income creates income record" do
    loan = create(:loan, lender: @lender, borrower: @borrower, contact: @contact,
                         amount: 10_000, date: 10.days.ago,
                         interest_mode: "from_start",
                         interest_rate: 0.01, interest_period: "daily",
                         interest_basis: "principal", status: "PENDING")
    assert_difference("Income.count", 1) do
      post "/api/loans/#{loan.id}/payments",
           params: {
             amount:                5000,
             paid_at:               Date.today.iso8601,
             add_interest_to_income: true
           }.to_json,
           headers: auth_header(@lender)
    end
    assert_response :created
    income = Income.last
    assert_includes income.source, @contact.name
  end

  test "add_interest_to_income false does not create income" do
    loan = create(:loan, lender: @lender, borrower: @borrower, contact: @contact,
                         amount: 10_000, date: 10.days.ago,
                         interest_mode: "from_start",
                         interest_rate: 0.01, interest_period: "daily",
                         interest_basis: "principal", status: "PENDING")
    assert_no_difference("Income.count") do
      post "/api/loans/#{loan.id}/payments",
           params: {
             amount:                5000,
             paid_at:               Date.today.iso8601,
             add_interest_to_income: false
           }.to_json,
           headers: auth_header(@lender)
    end
  end
end
```

- [ ] **Step 5.2: Run tests — verify they fail**

```bash
bin/rails test test/controllers/api/v1/loan_payments_controller_test.rb
```

Expected: routing errors or 404s since the controller and routes don't exist yet.

- [ ] **Step 5.3: Add routes**

In `rails_backend/config/routes.rb`, replace the `resources :loans` block:

```ruby
resources :loans, only: [:create, :index, :show, :update, :destroy] do
  member do
    post  :comments
    patch :confirmation
    get   'payments',  to: 'loan_payments#index'
    post  'payments',  to: 'loan_payments#create'
  end
end
```

- [ ] **Step 5.4: Create LoanPaymentsController**

Create `rails_backend/app/controllers/api/v1/loan_payments_controller.rb`:

```ruby
module Api
  module V1
    class LoanPaymentsController < ApplicationController
      before_action :set_loan

      def index
        render json: serialize_payments(@loan.loan_payments.order(paid_at: :desc))
      end

      def create
        return render json: { error: "Forbidden" }, status: :forbidden unless @loan.lender_for?(current_user.id)

        paid_at = params[:paid_at].present? ? Time.zone.parse(params[:paid_at]) : Time.current
        payment = @loan.loan_payments.create!(amount: params[:amount], paid_at: paid_at, note: params[:note])

        update_loan_status
        maybe_create_interest_income if ActiveModel::Type::Boolean.new.cast(params[:add_interest_to_income])

        calc = InterestCalculatorService.new(@loan.reload).call
        render json: {
          payment:  serialize_payment(payment),
          loan:     serialize_loan(@loan, calc)
        }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_loan
        @loan = Loan.for_user(current_user.id).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Loan not found" }, status: :not_found
      end

      def update_loan_status
        total_paid = @loan.loan_payments.sum(:amount)
        if total_paid >= @loan.amount
          @loan.update!(status: "PAID")
        elsif total_paid > 0
          @loan.update!(status: "PARTIAL")
        end
      end

      def maybe_create_interest_income
        calc = InterestCalculatorService.new(@loan).call
        return unless calc[:accrued_interest] > 0

        category = current_user.categories.find_or_create_by!(name: "Interest Income") do |c|
          c.applies_to = ["income"]
        end
        current_user.incomes.create!(
          source:      "Interest on loan: #{@loan.contact.name}",
          amount:      calc[:accrued_interest],
          date:        Date.today,
          category_id: category.id
        )
      end

      def serialize_payments(payments)
        payments.map { |p| serialize_payment(p) }
      end

      def serialize_payment(p)
        { id: p.id.to_s, loan_id: p.loan_id.to_s,
          amount: p.amount.to_f, paid_at: p.paid_at.iso8601,
          note: p.note, created_at: p.created_at.iso8601 }
      end

      def serialize_loan(l, calc)
        { id: l.id.to_s, status: l.status,
          outstanding: calc[:outstanding],
          accrued_interest: calc[:accrued_interest],
          total_due: calc[:total_due] }
      end
    end
  end
end
```

- [ ] **Step 5.5: Run tests — verify they pass**

```bash
bin/rails test test/controllers/api/v1/loan_payments_controller_test.rb
```

Expected: 9 tests, 0 failures.

- [ ] **Step 5.6: Commit**

```bash
git add app/controllers/api/v1/loan_payments_controller.rb \
        test/controllers/api/v1/loan_payments_controller_test.rb \
        config/routes.rb
git commit -m "feat(rails): LoanPaymentsController GET/POST + routes"
```

---

## Task 6: LoanRemindersController (POST) + routes

**Files:**
- Create: `rails_backend/app/controllers/api/v1/loan_reminders_controller.rb`
- Create: `rails_backend/test/controllers/api/v1/loan_reminders_controller_test.rb`
- Modify: `rails_backend/config/routes.rb`

- [ ] **Step 6.1: Write failing tests**

Create `rails_backend/test/controllers/api/v1/loan_reminders_controller_test.rb`:

```ruby
require "test_helper"

class Api::V1::LoanRemindersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lender   = create(:user)
    @borrower = create(:user)
    @contact  = create(:contact, owner: @lender, linked_user: @borrower)
    @loan     = create(:loan, lender: @lender, borrower: @borrower, contact: @contact)
  end

  test "lender can create a reminder" do
    assert_difference("LoanReminder.count", 1) do
      post "/api/loans/#{@loan.id}/reminders",
           params: {
             remind_at:      3.days.from_now.iso8601,
             nudge_borrower: true,
             via_push:       true,
             via_email:      true
           }.to_json,
           headers: auth_header(@lender)
    end
    assert_response :created
    reminder = LoanReminder.last
    assert reminder.nudge_borrower
    assert_equal @lender.id, reminder.set_by_user_id
  end

  test "borrower cannot create a reminder" do
    post "/api/loans/#{@loan.id}/reminders",
         params: { remind_at: 1.day.from_now.iso8601 }.to_json,
         headers: auth_header(@borrower)
    assert_response :forbidden
  end

  test "unrelated user gets 404" do
    post "/api/loans/#{@loan.id}/reminders",
         params: { remind_at: 1.day.from_now.iso8601 }.to_json,
         headers: auth_header(create(:user))
    assert_response :not_found
  end

  test "remind_at is required" do
    post "/api/loans/#{@loan.id}/reminders",
         params: {}.to_json,
         headers: auth_header(@lender)
    assert_response :bad_request
  end
end
```

- [ ] **Step 6.2: Run tests — verify they fail**

```bash
bin/rails test test/controllers/api/v1/loan_reminders_controller_test.rb
```

Expected: routing errors since route doesn't exist.

- [ ] **Step 6.3: Add reminders route**

In `rails_backend/config/routes.rb`, add `post 'reminders', to: 'loan_reminders#create'` inside the loans `member` block:

```ruby
resources :loans, only: [:create, :index, :show, :update, :destroy] do
  member do
    post  :comments
    patch :confirmation
    get   'payments',  to: 'loan_payments#index'
    post  'payments',  to: 'loan_payments#create'
    post  'reminders', to: 'loan_reminders#create'
  end
end
```

- [ ] **Step 6.4: Create LoanRemindersController**

Create `rails_backend/app/controllers/api/v1/loan_reminders_controller.rb`:

```ruby
module Api
  module V1
    class LoanRemindersController < ApplicationController
      before_action :set_loan

      def create
        unless @loan.lender_for?(current_user.id)
          return render json: { error: "Forbidden" }, status: :forbidden
        end
        remind_at = params[:remind_at].present? ? Time.zone.parse(params[:remind_at]) : nil
        unless remind_at
          return render json: { error: "remind_at is required" }, status: :bad_request
        end
        reminder = @loan.loan_reminders.create!(
          set_by_user_id: current_user.id,
          remind_at:      remind_at,
          nudge_borrower: ActiveModel::Type::Boolean.new.cast(params[:nudge_borrower]) || false,
          via_push:       ActiveModel::Type::Boolean.new.cast(params[:via_push]) != false,
          via_sms:        ActiveModel::Type::Boolean.new.cast(params[:via_sms]) || false,
          via_email:      ActiveModel::Type::Boolean.new.cast(params[:via_email]) != false
        )
        render json: {
          id:             reminder.id.to_s,
          loan_id:        reminder.loan_id.to_s,
          remind_at:      reminder.remind_at.iso8601,
          nudge_borrower: reminder.nudge_borrower,
          created_at:     reminder.created_at.iso8601
        }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :bad_request
      end

      private

      def set_loan
        @loan = Loan.for_user(current_user.id).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Loan not found" }, status: :not_found
      end
    end
  end
end
```

- [ ] **Step 6.5: Run tests — verify they pass**

```bash
bin/rails test test/controllers/api/v1/loan_reminders_controller_test.rb
```

Expected: 4 tests, 0 failures.

- [ ] **Step 6.6: Run full backend test suite**

```bash
bin/rails test
```

Expected: all tests pass, 0 failures.

- [ ] **Step 6.7: Commit**

```bash
git add app/controllers/api/v1/loan_reminders_controller.rb \
        test/controllers/api/v1/loan_reminders_controller_test.rb \
        config/routes.rb
git commit -m "feat(rails): LoanRemindersController POST + routes"
```

---

## Task 7: Flutter — LoanPayment model + update Loan model

**Files:**
- Create: `square_app/lib/features/transactions/data/loan_payment_model.dart`
- Create: `square_app/test/features/loans/loan_payment_model_test.dart`
- Modify: `square_app/lib/features/transactions/data/loan_model.dart`

- [ ] **Step 7.1: Write failing test for LoanPayment.fromJson**

Create `square_app/test/features/loans/loan_payment_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:square_app/features/transactions/data/loan_payment_model.dart';

void main() {
  group('LoanPayment.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': '42',
        'loan_id': '7',
        'amount': 1500.0,
        'paid_at': '2026-05-20T10:00:00.000Z',
        'note': 'First repayment',
        'created_at': '2026-05-20T10:01:00.000Z',
      };
      final p = LoanPayment.fromJson(json);
      expect(p.id, '42');
      expect(p.loanId, '7');
      expect(p.amount, 1500.0);
      expect(p.paidAt, DateTime.parse('2026-05-20T10:00:00.000Z'));
      expect(p.note, 'First repayment');
    });

    test('note is nullable', () {
      final json = {
        'id': '1', 'loan_id': '2', 'amount': 500.0,
        'paid_at': '2026-05-01T00:00:00.000Z',
        'created_at': '2026-05-01T00:00:00.000Z',
      };
      final p = LoanPayment.fromJson(json);
      expect(p.note, isNull);
    });
  });
}
```

- [ ] **Step 7.2: Run test — verify it fails**

```bash
cd square_app
flutter test test/features/loans/loan_payment_model_test.dart
```

Expected: compile error — `loan_payment_model.dart` not found.

- [ ] **Step 7.3: Create LoanPayment model**

Create `square_app/lib/features/transactions/data/loan_payment_model.dart`:

```dart
class LoanPayment {
  final String id;
  final String loanId;
  final double amount;
  final DateTime paidAt;
  final String? note;
  final DateTime createdAt;

  LoanPayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.paidAt,
    this.note,
    required this.createdAt,
  });

  factory LoanPayment.fromJson(Map<String, dynamic> json) => LoanPayment(
        id: json['id'] ?? '',
        loanId: json['loan_id'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        paidAt: DateTime.parse(json['paid_at']),
        note: json['note'],
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
      );
}
```

- [ ] **Step 7.4: Run test — verify it passes**

```bash
flutter test test/features/loans/loan_payment_model_test.dart
```

Expected: 2 tests, 0 failures.

- [ ] **Step 7.5: Update Loan model with computed fields**

In `square_app/lib/features/transactions/data/loan_model.dart`, add three optional fields to the class and `fromJson`. Add to the field declarations (after `final DateTime createdAt;`):

```dart
  final double outstanding;
  final double accruedInterest;
  final double totalDue;
```

Update the constructor to include them:

```dart
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
    double? outstanding,
    double? accruedInterest,
    double? totalDue,
  })  : outstanding = outstanding ?? amount,
        accruedInterest = accruedInterest ?? 0.0,
        totalDue = totalDue ?? amount;
```

Update `fromJson` to parse the new fields:

```dart
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
        outstanding: (json['outstanding'] as num?)?.toDouble(),
        accruedInterest: (json['accrued_interest'] as num?)?.toDouble(),
        totalDue: (json['total_due'] as num?)?.toDouble(),
```

- [ ] **Step 7.6: Run existing Flutter tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 7.7: Commit**

```bash
cd ..
git add square_app/lib/features/transactions/data/loan_payment_model.dart \
        square_app/lib/features/transactions/data/loan_model.dart \
        square_app/test/features/loans/loan_payment_model_test.dart
git commit -m "feat(flutter): LoanPayment model, Loan computed fields"
```

---

## Task 8: Flutter — LoansRepository

**Files:**
- Create: `square_app/lib/features/loans/data/loans_repository.dart`

- [ ] **Step 8.1: Create directory**

```bash
mkdir -p square_app/lib/features/loans/data
mkdir -p square_app/lib/features/loans/presentation/widgets
```

- [ ] **Step 8.2: Create LoansRepository**

Create `square_app/lib/features/loans/data/loans_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../transactions/data/loan_model.dart';
import '../../transactions/data/loan_payment_model.dart';

class LoanDetail {
  final Loan loan;
  final List<LoanPayment> payments;
  final List<Map<String, dynamic>> interestTimeline;

  LoanDetail({
    required this.loan,
    required this.payments,
    required this.interestTimeline,
  });
}

class LoansRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<LoanDetail> getLoan(String token, String loanId) async {
    try {
      final res = await _dio.get(
        '/loans/$loanId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = res.data as Map<String, dynamic>;
      final loan = Loan.fromJson(data['loan']);
      final payments = (data['payments'] as List? ?? [])
          .map((j) => LoanPayment.fromJson(j as Map<String, dynamic>))
          .toList();
      final timeline = (data['interest_timeline'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      return LoanDetail(loan: loan, payments: payments, interestTimeline: timeline);
    } catch (e) {
      throw Exception('Failed to fetch loan: $e');
    }
  }

  Future<Map<String, dynamic>> recordPayment(
    String token,
    String loanId, {
    required double amount,
    required DateTime paidAt,
    String? note,
    bool addInterestToIncome = false,
  }) async {
    try {
      final res = await _dio.post(
        '/loans/$loanId/payments',
        data: {
          'amount':                 amount,
          'paid_at':                paidAt.toIso8601String(),
          if (note != null) 'note': note,
          'add_interest_to_income': addInterestToIncome,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to record payment: $e');
    }
  }

  Future<void> setReminder(
    String token,
    String loanId, {
    required DateTime remindAt,
    bool nudgeBorrower = false,
    bool viaPush = true,
    bool viaEmail = true,
    bool viaSms = false,
  }) async {
    try {
      await _dio.post(
        '/loans/$loanId/reminders',
        data: {
          'remind_at':      remindAt.toIso8601String(),
          'nudge_borrower': nudgeBorrower,
          'via_push':       viaPush,
          'via_email':      viaEmail,
          'via_sms':        viaSms,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to set reminder: $e');
    }
  }

  Future<Map<String, dynamic>> updateConfirmation(
    String token,
    String loanId,
    String confirmationStatus,
  ) async {
    try {
      final res = await _dio.patch(
        '/loans/$loanId/confirmation',
        data: {'confirmation_status': confirmationStatus},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update confirmation: $e');
    }
  }
}

final loansRepositoryProvider = Provider((ref) => LoansRepository());
```

- [ ] **Step 8.3: Commit**

```bash
git add square_app/lib/features/loans/
git commit -m "feat(flutter): LoansRepository with getLoan, recordPayment, setReminder"
```

---

## Task 9: Flutter — LoanDetailScreen + InterestTimelineCard

**Files:**
- Create: `square_app/lib/features/loans/presentation/loan_detail_screen.dart`
- Create: `square_app/lib/features/loans/presentation/widgets/interest_timeline_card.dart`

- [ ] **Step 9.1: Create InterestTimelineCard widget**

Create `square_app/lib/features/loans/presentation/widgets/interest_timeline_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/utils/currency_formatter.dart';

class InterestTimelineCard extends StatefulWidget {
  final List<Map<String, dynamic>> timeline;
  final double accruedInterest;
  final double dailyRate;
  final bool isDark;

  const InterestTimelineCard({
    super.key,
    required this.timeline,
    required this.accruedInterest,
    required this.dailyRate,
    required this.isDark,
  });

  @override
  State<InterestTimelineCard> createState() => _InterestTimelineCardState();
}

class _InterestTimelineCardState extends State<InterestTimelineCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.timeline.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF111111)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.trending_up,
                      size: 18,
                      color: Colors.orange[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accrued Interest',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Text(
                          formatInr(widget.accruedInterest),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.timeline.length,
                itemBuilder: (_, i) {
                  final entry = widget.timeline[i];
                  final date = DateTime.parse(entry['date'] as String);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('dd MMM').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '+${formatInr((entry['daily_interest'] as num).toDouble())}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.orange),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: Text(
                            formatInr(
                                (entry['cumulative'] as num).toDouble()),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 9.2: Create LoanDetailScreen**

Create `square_app/lib/features/loans/presentation/loan_detail_screen.dart`:

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/auth/data/user_model.dart';
import '../data/loans_repository.dart';
import 'widgets/interest_timeline_card.dart';
import 'widgets/record_payment_sheet.dart';
import 'widgets/reminder_sheet.dart';

final _loanDetailProvider = FutureProvider.family<LoanDetail, String>(
  (ref, loanId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return ref.read(loansRepositoryProvider).getLoan(token, loanId);
  },
);

class LoanDetailScreen extends ConsumerWidget {
  final String loanId;
  const LoanDetailScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_loanDetailProvider(loanId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF7F7F7),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) => _LoanDetailBody(
          detail: detail,
          loanId: loanId,
          isDark: isDark,
          onRefresh: () => ref.invalidate(_loanDetailProvider(loanId)),
        ),
      ),
    );
  }
}

class _LoanDetailBody extends ConsumerWidget {
  final LoanDetail detail;
  final String loanId;
  final bool isDark;
  final VoidCallback onRefresh;

  const _LoanDetailBody({
    required this.detail,
    required this.loanId,
    required this.isDark,
    required this.onRefresh,
  });

  Future<String?> _currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData == null) return null;
    return User.fromJson(jsonDecode(userData)).id;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loan = detail.loan;
    final isLent = loan.direction == 'lent';
    final accentColor = isLent ? Colors.green[600]! : Colors.red[400]!;

    return FutureBuilder<String?>(
      future: _currentUserId(),
      builder: (context, snap) {
        final currentUserId = snap.data;
        final isLender = currentUserId != null &&
            loan.lenderUserId == currentUserId;
        final isBorrower = currentUserId != null &&
            loan.borrowerUserId == currentUserId;

        return Scaffold(
          backgroundColor:
              isDark ? Colors.black : const Color(0xFFF7F7F7),
          appBar: AppBar(
            backgroundColor:
                isDark ? Colors.black : const Color(0xFFF7F7F7),
            elevation: 0,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft,
                  color: isDark ? Colors.white : Colors.black),
              onPressed: () => context.pop(),
            ),
            title: Text(
              loan.contactName,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            actions: [
              if (isLender)
                IconButton(
                  icon: Icon(LucideIcons.bell,
                      color: isDark ? Colors.white70 : Colors.black54),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('token') ?? '';
                    if (context.mounted) {
                      ReminderSheet.show(
                        context,
                        loan: loan,
                        token: token,
                        repository: ref.read(loansRepositoryProvider),
                      );
                    }
                  },
                ),
            ],
          ),
          floatingActionButton: isLender && loan.status != 'PAID'
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('token') ?? '';
                    if (context.mounted) {
                      await RecordPaymentSheet.show(
                        context,
                        loan: loan,
                        token: token,
                        repository: ref.read(loansRepositoryProvider),
                      );
                      onRefresh();
                    }
                  },
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  icon: const Icon(LucideIcons.checkCircle, size: 18),
                  label: const Text('Record Payment',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _AmountCard(loan: loan, accentColor: accentColor, isDark: isDark),
              if (loan.interestMode != 'none')
                InterestTimelineCard(
                  timeline: detail.interestTimeline,
                  accruedInterest: loan.accruedInterest,
                  dailyRate: 0,
                  isDark: isDark,
                ),
              if (isBorrower && loan.status != 'PAID')
                _ConfirmationBar(
                  loan: loan,
                  token: '',
                  repository: ref.read(loansRepositoryProvider),
                  onUpdated: onRefresh,
                ),
              _SectionHeader(label: 'Payment History', isDark: isDark),
              if (detail.payments.isEmpty)
                _EmptyPayments(isDark: isDark)
              else
                ...detail.payments.map(
                  (p) => _PaymentTile(payment: p, isDark: isDark),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AmountCard extends StatelessWidget {
  final loan;
  final Color accentColor;
  final bool isDark;

  const _AmountCard(
      {required this.loan, required this.accentColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: loan.direction == 'lent'
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  loan.direction == 'lent' ? 'LENT' : 'BORROWED',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accentColor),
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: loan.status),
              if (loan.confirmationStatus == 'confirmed')
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Confirmed',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue)),
                ),
              if (loan.confirmationStatus == 'disputed')
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Disputed',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatInr(loan.amount),
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: accentColor),
          ),
          if (loan.description != null && loan.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(loan.description!,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black45)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoPair(
                  label: 'Date',
                  value: DateFormat('dd MMM y').format(loan.date),
                  isDark: isDark),
              if (loan.dueDate != null) ...[
                const SizedBox(width: 24),
                _InfoPair(
                    label: 'Due',
                    value: DateFormat('dd MMM y').format(loan.dueDate!),
                    isDark: isDark),
              ],
            ],
          ),
          if (loan.interestMode != 'none') ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoPair(
                    label: 'Outstanding',
                    value: formatInr(loan.outstanding),
                    isDark: isDark),
                const SizedBox(width: 24),
                _InfoPair(
                    label: 'Total Due',
                    value: formatInr(loan.totalDue),
                    isDark: isDark,
                    highlight: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'PAID':
        color = Colors.green[600]!;
        break;
      case 'PARTIAL':
        color = Colors.blue[400]!;
        break;
      default:
        color = Colors.amber[600]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _InfoPair extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;

  const _InfoPair(
      {required this.label,
      required this.value,
      required this.isDark,
      this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white38 : Colors.black38)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight
                    ? Colors.orange[400]
                    : (isDark ? Colors.white70 : Colors.black87))),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}

class _EmptyPayments extends StatelessWidget {
  final bool isDark;
  const _EmptyPayments({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No payments recorded yet',
          style: TextStyle(
              color: isDark ? Colors.white30 : Colors.black26,
              fontSize: 13),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final payment;
  final bool isDark;
  const _PaymentTile({required this.payment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.checkCircle,
                size: 16, color: Colors.green[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.note ?? 'Payment',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  DateFormat('dd MMM y').format(payment.paidAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            formatInr(payment.amount),
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.green[600]),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationBar extends StatelessWidget {
  final loan;
  final String token;
  final LoansRepository repository;
  final VoidCallback onUpdated;

  const _ConfirmationBar({
    required this.loan,
    required this.token,
    required this.repository,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (loan.confirmationStatus != 'pending') return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirm this loan?',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: Colors.blue)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await repository.updateConfirmation(token, loan.id, 'confirmed');
                    onUpdated();
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[600],
                      side: BorderSide(color: Colors.green[600]!)),
                  child: const Text('Confirm'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await repository.updateConfirmation(token, loan.id, 'disputed');
                    onUpdated();
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[400],
                      side: BorderSide(color: Colors.red[400]!)),
                  child: const Text('Dispute'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 9.3: Commit**

```bash
cd ..
git add square_app/lib/features/loans/presentation/
git commit -m "feat(flutter): LoanDetailScreen + InterestTimelineCard"
```

---

## Task 10: Flutter — RecordPaymentSheet

**Files:**
- Create: `square_app/lib/features/loans/presentation/widgets/record_payment_sheet.dart`

- [ ] **Step 10.1: Create RecordPaymentSheet**

Create `square_app/lib/features/loans/presentation/widgets/record_payment_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../transactions/data/loan_model.dart';
import '../../data/loans_repository.dart';

class RecordPaymentSheet extends StatefulWidget {
  final Loan loan;
  final String token;
  final LoansRepository repository;

  const RecordPaymentSheet({
    super.key,
    required this.loan,
    required this.token,
    required this.repository,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Loan loan,
    required String token,
    required LoansRepository repository,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPaymentSheet(
          loan: loan, token: token, repository: repository),
    );
  }

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  DateTime _paidAt = DateTime.now();
  bool _addInterestToIncome = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
        text: widget.loan.totalDue.toStringAsFixed(2));
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repository.recordPayment(
        widget.token,
        widget.loan.id,
        amount: amount,
        paidAt: _paidAt,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        addInterestToIncome: _addInterestToIncome,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasInterest = widget.loan.accruedInterest > 0;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Record Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Outstanding: ${formatInr(widget.loan.outstanding)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'))
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _paidAt,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _paidAt = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar,
                        size: 16,
                        color:
                            isDark ? Colors.white60 : Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM y').format(_paidAt),
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (hasInterest) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Add ${formatInr(widget.loan.accruedInterest)} interest to Income',
                  style: const TextStyle(fontSize: 13),
                ),
                value: _addInterestToIncome,
                onChanged: (v) => setState(() => _addInterestToIncome = v),
                dense: true,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style:
                      const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Payment',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 10.2: Commit**

```bash
git add square_app/lib/features/loans/presentation/widgets/record_payment_sheet.dart
git commit -m "feat(flutter): RecordPaymentSheet"
```

---

## Task 11: Flutter — ReminderSheet

**Files:**
- Create: `square_app/lib/features/loans/presentation/widgets/reminder_sheet.dart`

- [ ] **Step 11.1: Create ReminderSheet**

Create `square_app/lib/features/loans/presentation/widgets/reminder_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../transactions/data/loan_model.dart';
import '../../data/loans_repository.dart';

class ReminderSheet extends StatefulWidget {
  final Loan loan;
  final String token;
  final LoansRepository repository;

  const ReminderSheet({
    super.key,
    required this.loan,
    required this.token,
    required this.repository,
  });

  static void show(
    BuildContext context, {
    required Loan loan,
    required String token,
    required LoansRepository repository,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ReminderSheet(loan: loan, token: token, repository: repository),
    );
  }

  @override
  State<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<ReminderSheet> {
  DateTime? _selectedDate;
  bool _nudgeBorrower = false;
  bool _loading = false;
  String? _error;

  void _selectQuickDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      setState(() => _error = 'Select a date');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repository.setReminder(
        widget.token,
        widget.loan.id,
        remindAt: _selectedDate!,
        nudgeBorrower: _nudgeBorrower,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder set')),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDueDate = widget.loan.dueDate != null;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final inThreeDays = DateTime.now().add(const Duration(days: 3));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Set Reminder',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _QuickChip(
                label: 'Tomorrow',
                selected: _selectedDate != null &&
                    _isSameDay(_selectedDate!, tomorrow),
                onTap: () => _selectQuickDate(tomorrow),
                isDark: isDark,
              ),
              _QuickChip(
                label: 'In 3 days',
                selected: _selectedDate != null &&
                    _isSameDay(_selectedDate!, inThreeDays),
                onTap: () => _selectQuickDate(inThreeDays),
                isDark: isDark,
              ),
              _QuickChip(
                label: 'On due date',
                selected: hasDueDate &&
                    _selectedDate != null &&
                    _isSameDay(_selectedDate!, widget.loan.dueDate!),
                onTap: hasDueDate
                    ? () => _selectQuickDate(widget.loan.dueDate!)
                    : null,
                isDark: isDark,
                disabled: !hasDueDate,
              ),
              _QuickChip(
                label: 'Custom',
                selected: _selectedDate != null &&
                    !_isSameDay(_selectedDate!, tomorrow) &&
                    !_isSameDay(_selectedDate!, inThreeDays) &&
                    !(hasDueDate &&
                        _isSameDay(_selectedDate!, widget.loan.dueDate!)),
                onTap: _pickCustomDate,
                isDark: isDark,
                icon: LucideIcons.calendar,
              ),
            ],
          ),
          if (_selectedDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reminder: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          if (widget.loan.borrowerUserId != null) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Also nudge ${widget.loan.contactName}',
                style: const TextStyle(fontSize: 13),
              ),
              value: _nudgeBorrower,
              onChanged: (v) => setState(() => _nudgeBorrower = v),
              dense: true,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style:
                    const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Set Reminder',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool isDark;
  final bool disabled;
  final IconData? icon;

  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    this.disabled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.orange[600]
              : disabled
                  ? (isDark
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFF0F0F0))
                  : (isDark
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(
                  color: isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFDDDDDD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: disabled
                      ? Colors.grey
                      : (selected ? Colors.white : null)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: disabled
                    ? Colors.grey
                    : (selected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 11.2: Commit**

```bash
git add square_app/lib/features/loans/presentation/widgets/reminder_sheet.dart
git commit -m "feat(flutter): ReminderSheet with quick chips + nudge toggle"
```

---

## Task 12: Wire up router + loan tile navigation

**Files:**
- Modify: `square_app/lib/core/router.dart`
- Modify: `square_app/lib/features/transactions/presentation/transactions_screen.dart`

- [ ] **Step 12.1: Update router — replace loan detail placeholder**

In `square_app/lib/core/router.dart`, add the import at the top:

```dart
import '../../features/loans/presentation/loan_detail_screen.dart';
```

Replace the placeholder `/loans/:id` route:

```dart
GoRoute(
  path: '/loans/:id',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) =>
      LoanDetailScreen(loanId: state.pathParameters['id']!),
),
```

- [ ] **Step 12.2: Update loan tile onTap in TransactionsScreen**

In `square_app/lib/features/transactions/presentation/transactions_screen.dart`, inside `_buildTransactionCard`, find the `else if (item is Loan)` block. Change:

```dart
onTap: () {},
```

to:

```dart
onTap: () => context.push('/loans/${item.id}'),
```

- [ ] **Step 12.3: Update _ConfirmationBar token in LoanDetailScreen**

In `square_app/lib/features/loans/presentation/loan_detail_screen.dart`, the `_ConfirmationBar` is built with `token: ''`. Fix it to pass the token from SharedPreferences.

Replace the `_ConfirmationBar` instantiation inside `_LoanDetailBody.build`:

```dart
if (isBorrower && loan.status != 'PAID')
  FutureBuilder<String>(
    future: () async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token') ?? '';
    }(),
    builder: (context, snap) {
      final token = snap.data ?? '';
      return _ConfirmationBar(
        loan: loan,
        token: token,
        repository: ref.read(loansRepositoryProvider),
        onUpdated: onRefresh,
      );
    },
  ),
```

- [ ] **Step 12.4: Run Flutter analyzer**

```bash
cd square_app
flutter analyze
```

Expected: no errors. Fix any type warnings before proceeding.

- [ ] **Step 12.5: Commit**

```bash
cd ..
git add square_app/lib/core/router.dart \
        square_app/lib/features/transactions/presentation/transactions_screen.dart \
        square_app/lib/features/loans/presentation/loan_detail_screen.dart
git commit -m "feat(flutter): wire LoanDetailScreen into router + loan list navigation"
```

---

## Self-Review Checklist

Spec sections checked against tasks:

| Spec Section | Covered By |
|---|---|
| §3 Interest Engine (none/from_start/penalty, basis, rate normalization) | Task 3 |
| §4 Payment & Settlement (RecordPayment sheet, status update, income toggle) | Tasks 1, 5, 10 |
| §6 Reminders (lender-only, quick chips, nudge toggle) | Tasks 2, 6, 11 |
| §7 API `POST /loans/:id/payments` | Task 5 |
| §7 API `GET /loans/:id/payments` | Task 5 |
| §7 API `POST /loans/:id/reminders` | Task 6 |
| §7 API `GET /loans` computed fields | Task 4 |
| §7 API `GET /loans/:id` enriched | Task 4 |
| §8 Flutter `LoanDetailScreen` | Task 9 |
| §8 Flutter `RecordPaymentSheet` | Task 10 |
| §8 Flutter `InterestTimelineCard` | Task 9 |
| §8 Flutter `ReminderSheet` | Task 11 |
| §8 Flutter model updates (Loan + LoanPayment) | Task 7 |

**Borrower notification on payment recorded (§4 step 6):** The spec calls for a push/email/SMS notification to the borrower when a payment is recorded. Actual notification delivery requires a background job / mailer integration. This plan stores the data; notification delivery is a follow-on task.

**Reminder delivery (§6):** `sent_at` is stored on `LoanReminder` but actual delivery requires a background scheduler. This plan stores reminders; delivery is a follow-on task.
