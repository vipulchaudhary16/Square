# Group Expense Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every group a "Reports" tab showing the same period-scoped analysis UI the personal Analysis tab already has, with "Total expense" and "Your share" stat tiles instead of Spending/Income, and a "Your share" tap-through into the existing transaction drilldown filtered to that group + the current user.

**Architecture:** Extract a small `AnalysisService.summarize` aggregator and an `Expense#split_for(user_id)` method on the Rails side, add one new group-scoped endpoint that reuses both, and fix a pre-existing PERCENT-split bug in `DebtSettlementService` along the way (it needs the exact same per-user-share logic). On the Flutter side, extract the personal Analysis screen's two private stat/toggle widgets into `lib/shared/widgets/`, build one new `AnalysisReportView` composable from them, and make both the personal screen and the new group Reports tab render through it. Extend the existing transaction drilldown (route, provider, repository call) with an optional `groupId` filter so "Your share" reuses that exact screen instead of building a new one.

**Tech Stack:** Rails 7 (Minitest + FactoryBot, no RSpec in this repo) for `rails_backend/`; Flutter + Riverpod + go_router for `square_app/`.

**Spec:** `docs/superpowers/specs/2026-08-22-group-expense-report-design.md`

## Global Constraints

- Backend tests run with `bin/rails test <path>` (this repo uses Minitest + FactoryBot, not RSpec — verified, no `spec/` directory exists).
- Frontend: `flutter analyze` must stay clean after every task. **No Dart/Flutter test files are written in this plan** (explicit user instruction) — every Flutter task is verified via `flutter analyze` plus the manual emulator walkthrough in the final task, not automated tests.
- Test convention for the backend (matches this repo's existing, real conventions): Rails gets full model/service/controller test coverage for every new/changed method, mirroring the existing `test/controllers/api/v1/loans_controller_test.rb` style (Minitest `ActionDispatch::IntegrationTest` + `auth_header(user)` + FactoryBot `create(...)`).
- `Expense#split_for(user_id)` takes a raw user id (integer, matching `expense_splits.user_id`/`current_user.id`), not a `User` object — `DebtSettlementService` needs to call it for arbitrary participant ids, not just "the current user."
- None of the test/factory files this plan needs exist yet (`test/factories/groups.rb`, `categories.rb`, `expenses.rb`, `expense_splits.rb`, `expense_participants.rb`; `test/models/expense_test.rb`; `test/services/debt_settlement_service_test.rb`, `analysis_service_test.rb`; `test/controllers/api/v1/analysis_controller_test.rb`, `groups_controller_test.rb`, `expenses_controller_test.rb` — confirmed missing by direct file check). Every backend test task below creates a new file, not an extension of an existing one.

---

## Task 1: `Expense#split_for(user_id)` + supporting factories

**Files:**
- Create: `rails_backend/test/factories/categories.rb`
- Create: `rails_backend/test/factories/expenses.rb`
- Create: `rails_backend/test/factories/expense_splits.rb`
- Create: `rails_backend/test/factories/expense_participants.rb`
- Modify: `rails_backend/app/models/expense.rb`
- Test: `rails_backend/test/models/expense_test.rb`

**Interfaces:**
- Produces: `Expense#split_for(user_id) -> Float` — the exact user's dollar share of this expense (from `expense_splits` if present, else an equal cut of `expense_participants`, else `0.0`). Used by Task 2 (`DebtSettlementService`) and Task 5 (`GroupsController#group_analysis`).
- Produces: factories `:category`, `:expense`, `:expense_split`, `:expense_participant` — used by every backend task after this one.

- [ ] **Step 1: Create the four factory files**

`rails_backend/test/factories/categories.rb`:
```ruby
FactoryBot.define do
  factory :category do
    association :user
    sequence(:name) { |n| "Category #{n}" }
    applies_to { ["expense"] }
    color { "#FF5733" }
    is_standard { false }
  end
end
```

`rails_backend/test/factories/expenses.rb`:
```ruby
FactoryBot.define do
  factory :expense do
    association :payer, factory: :user
    category { association(:category, user: payer) }
    group { nil }
    description { "Test expense" }
    amount { 100.0 }
    date { Time.current }
    split_type { "EQUAL" }
  end
end
```

`rails_backend/test/factories/expense_splits.rb`:
```ruby
FactoryBot.define do
  factory :expense_split do
    association :expense
    association :user
    amount { 50.0 }
  end
end
```

`rails_backend/test/factories/expense_participants.rb`:
```ruby
FactoryBot.define do
  factory :expense_participant do
    association :expense
    association :user
  end
end
```

- [ ] **Step 2: Write the failing test**

Create `rails_backend/test/models/expense_test.rb`:
```ruby
require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  setup do
    @payer = create(:user)
    @participant = create(:user)
    @outsider = create(:user)
    @category = create(:category, user: @payer)
  end

  test "split_for returns the stored split amount when expense_splits exist" do
    expense = create(:expense, payer: @payer, category: @category, amount: 100.0, split_type: "EXACT")
    create(:expense_split, expense: expense, user: @payer, amount: 60.0)
    create(:expense_split, expense: expense, user: @participant, amount: 40.0)

    assert_equal 40.0, expense.split_for(@participant.id)
    assert_equal 60.0, expense.split_for(@payer.id)
  end

  test "split_for divides equally among participants when no splits exist" do
    expense = create(:expense, payer: @payer, category: @category, amount: 90.0, split_type: "EQUAL")
    create(:expense_participant, expense: expense, user: @payer)
    create(:expense_participant, expense: expense, user: @participant)
    create(:expense_participant, expense: expense, user: @outsider)

    assert_equal 30.0, expense.split_for(@participant.id)
  end

  test "split_for returns 0 for a user with no split and no participant row" do
    expense = create(:expense, payer: @payer, category: @category, amount: 100.0)
    create(:expense_participant, expense: expense, user: @payer)

    assert_equal 0.0, expense.split_for(@outsider.id)
  end
end
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd rails_backend && bin/rails test test/models/expense_test.rb`
Expected: `NoMethodError: undefined method 'split_for' for an instance of Expense`

- [ ] **Step 4: Implement `split_for`**

In `rails_backend/app/models/expense.rb`, add this method (place it directly above `group_summary_json`):
```ruby
  def split_for(user_id)
    split = expense_splits.find { |s| s.user_id == user_id }
    return split.amount.to_f if split
    return 0.0 unless expense_participants.any? { |p| p.user_id == user_id }
    amount / expense_participants.size.to_f
  end

```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd rails_backend && bin/rails test test/models/expense_test.rb`
Expected: 3 runs, 0 failures, 0 errors.

- [ ] **Step 6: Commit**

```bash
git add rails_backend/test/factories/categories.rb rails_backend/test/factories/expenses.rb rails_backend/test/factories/expense_splits.rb rails_backend/test/factories/expense_participants.rb rails_backend/test/models/expense_test.rb rails_backend/app/models/expense.rb
git commit -m "feat(rails): add Expense#split_for(user_id) as the single source of truth for a user's share"
```

---

## Task 2: Fix the PERCENT-split bug in `DebtSettlementService`

**Files:**
- Modify: `rails_backend/app/services/debt_settlement_service.rb`
- Test: `rails_backend/test/services/debt_settlement_service_test.rb`

**Interfaces:**
- Consumes: `Expense#split_for(user_id)` from Task 1.
- Produces: no interface change — `DebtSettlementService.compute(expenses, settlements)` keeps its exact signature and `Debt` struct shape; only its internal per-user-share math is corrected.

- [ ] **Step 1: Write the failing test**

Create `rails_backend/test/services/debt_settlement_service_test.rb`:
```ruby
require "test_helper"

class DebtSettlementServiceTest < ActiveSupport::TestCase
  setup do
    @alice = create(:user)
    @bob   = create(:user)
    @category = create(:category, user: @alice)
  end

  test "equal split between payer and one participant" do
    expense = create(:expense, payer: @alice, category: @category, amount: 100.0, split_type: "EQUAL")
    create(:expense_participant, expense: expense, user: @alice)
    create(:expense_participant, expense: expense, user: @bob)
    create(:expense_split, expense: expense, user: @alice, amount: 50.0)
    create(:expense_split, expense: expense, user: @bob, amount: 50.0)

    debts = DebtSettlementService.compute([expense])
    assert_equal 1, debts.size
    assert_equal @bob.id, debts.first.from_id
    assert_equal @alice.id, debts.first.to_id
    assert_in_delta 50.0, debts.first.amount, 0.01
  end

  test "PERCENT split computes the correct amount owed, not the amount divided by 100 again" do
    expense = create(:expense, payer: @alice, category: @category, amount: 200.0, split_type: "PERCENT")
    create(:expense_split, expense: expense, user: @alice, amount: 150.0) # 75% resolved to dollars
    create(:expense_split, expense: expense, user: @bob,   amount: 50.0)  # 25% resolved to dollars

    debts = DebtSettlementService.compute([expense])
    assert_equal 1, debts.size
    assert_equal @bob.id, debts.first.from_id
    assert_equal @alice.id, debts.first.to_id
    assert_in_delta 50.0, debts.first.amount, 0.01
  end

  test "participants without explicit splits divide the amount equally" do
    expense = create(:expense, payer: @alice, category: @category, amount: 90.0, split_type: "EQUAL")
    create(:expense_participant, expense: expense, user: @alice)
    create(:expense_participant, expense: expense, user: @bob)

    debts = DebtSettlementService.compute([expense])
    assert_in_delta 45.0, debts.first.amount, 0.01
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd rails_backend && bin/rails test test/services/debt_settlement_service_test.rb`
Expected: the "PERCENT split" test FAILS — current code computes `200.0 * 50.0 / 100.0 = 100.0` instead of `50.0`, so `debts.first.amount` is `150.0` not `50.0` (the double-percentage bug). The other two tests pass already (they don't exercise the bug).

- [ ] **Step 3: Fix the implementation**

Replace the `expenses.each do |exp| ... end` block in `rails_backend/app/services/debt_settlement_service.rb` (currently lines 6-23) with:
```ruby
    expenses.each do |exp|
      amount = exp.amount.to_f
      net[exp.payer_id] += amount

      user_ids = (exp.expense_splits.map(&:user_id) + exp.expense_participants.map(&:user_id)).uniq
      user_ids.each { |uid| net[uid] -= exp.split_for(uid) }
    end
```
Everything else in the file (the settlements loop, the greedy debtor/creditor matching, the `Debt` struct) stays exactly as-is.

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd rails_backend && bin/rails test test/services/debt_settlement_service_test.rb`
Expected: 3 runs, 0 failures, 0 errors.

- [ ] **Step 5: Commit**

```bash
git add rails_backend/app/services/debt_settlement_service.rb rails_backend/test/services/debt_settlement_service_test.rb
git commit -m "fix(rails): correct PERCENT-split double-division bug in DebtSettlementService via Expense#split_for"
```

---

## Task 3: `Expense.with_filters` gains a `group_id` filter

**Files:**
- Create: `rails_backend/test/factories/groups.rb`
- Modify: `rails_backend/app/models/expense.rb`
- Test: `rails_backend/test/models/expense_test.rb` (append)
- Test: `rails_backend/test/controllers/api/v1/expenses_controller_test.rb`

**Interfaces:**
- Produces: factory `:group` (transient `members:` array, auto-creates a `GroupMembership` for `created_by` and each transient member) — used by this task and Tasks 5, 6.
- Produces: `Expense.with_filters(params)` now also accepts `params[:group_id]` — used by Task 5's `group_analysis` action and by the Flutter drilldown extension in Task 12.

- [ ] **Step 1: Create the group factory**

`rails_backend/test/factories/groups.rb`:
```ruby
FactoryBot.define do
  factory :group do
    association :created_by, factory: :user
    name { "Test Group" }
    description { "" }

    transient do
      members { [] }
    end

    after(:create) do |group, evaluator|
      GroupMembership.find_or_create_by!(group: group, user: group.created_by)
      evaluator.members.each { |u| GroupMembership.find_or_create_by!(group: group, user: u) }
    end
  end
end
```

- [ ] **Step 2: Write the failing model-level test**

Append to `rails_backend/test/models/expense_test.rb` (inside the existing `class ExpenseTest`, after the last `test` block):
```ruby

  test "with_filters scopes to a specific group when group_id is given" do
    group1 = create(:group, created_by: @payer)
    group2 = create(:group, created_by: @payer)
    e1 = create(:expense, payer: @payer, category: @category, group: group1)
    e2 = create(:expense, payer: @payer, category: @category, group: group2)

    result = Expense.with_filters(group_id: group1.id.to_s)
    assert_includes result, e1
    assert_not_includes result, e2
  end
```

- [ ] **Step 3: Write the failing controller-level test**

Create `rails_backend/test/controllers/api/v1/expenses_controller_test.rb`:
```ruby
require "test_helper"

class Api::V1::ExpensesControllerTest < ActionDispatch::IntegrationTest
  test "index filters to a single group even when the user has expenses in multiple groups" do
    alice = create(:user)
    bob   = create(:user)
    group1 = create(:group, created_by: alice, members: [bob])
    group2 = create(:group, created_by: alice, members: [bob])
    category = create(:category, user: alice)

    in_group1 = create(:expense, payer: alice, category: category, group: group1, amount: 30.0)
    create(:expense_participant, expense: in_group1, user: bob)

    in_group2 = create(:expense, payer: alice, category: category, group: group2, amount: 20.0)
    create(:expense_participant, expense: in_group2, user: bob)

    get "/api/expenses", params: { group_id: group1.id.to_s }, headers: auth_header(bob)

    assert_response :ok
    ids = JSON.parse(response.body).map { |e| e["id"] }
    assert_includes ids, in_group1.id.to_s
    assert_not_includes ids, in_group2.id.to_s
  end
end
```

- [ ] **Step 4: Run both tests to verify they fail**

Run: `cd rails_backend && bin/rails test test/models/expense_test.rb test/controllers/api/v1/expenses_controller_test.rb`
Expected: both new tests FAIL (`group2`'s expense/`in_group2` is wrongly included — `with_filters` currently ignores `group_id` entirely).

- [ ] **Step 5: Implement the filter**

In `rails_backend/app/models/expense.rb`, change the `with_filters` scope to:
```ruby
  scope :with_filters, ->(params) {
    s = all
    s = s.where(group_id: nil) if params[:personal_only] == "true"
    s = s.where(group_id: params[:group_id]) if params[:group_id].present?
    s = s.where(category_id: params[:category_id]) if params[:category_id].present?
    s = s.where("date >= ?", params[:start_date]) if params[:start_date].present?
    s = s.where("date <= ?", params[:end_date]) if params[:end_date].present?
    s = s.where("description ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:search])}%") if params[:search].present?
    s
  }
```

- [ ] **Step 6: Run both tests to verify they pass**

Run: `cd rails_backend && bin/rails test test/models/expense_test.rb test/controllers/api/v1/expenses_controller_test.rb`
Expected: all runs pass, 0 failures, 0 errors.

- [ ] **Step 7: Commit**

```bash
git add rails_backend/test/factories/groups.rb rails_backend/app/models/expense.rb rails_backend/test/models/expense_test.rb rails_backend/test/controllers/api/v1/expenses_controller_test.rb
git commit -m "feat(rails): Expense.with_filters accepts an optional group_id"
```

---

## Task 4: Extract `AnalysisService.summarize`, update `AnalysisController`

**Files:**
- Create: `rails_backend/app/services/analysis_service.rb`
- Modify: `rails_backend/app/controllers/api/v1/analysis_controller.rb`
- Test: `rails_backend/test/services/analysis_service_test.rb`
- Test: `rails_backend/test/controllers/api/v1/analysis_controller_test.rb`

**Interfaces:**
- Consumes: `Expense#split_for(user_id)` from Task 1 (used in one test as a custom `value:` extractor).
- Produces: `AnalysisService.summarize(scope, value: ->(record) { record.amount }) -> {total:, count:, by_category: [...]}`. Used by this task's controller and by Task 5's `group_analysis`.

- [ ] **Step 1: Write the failing service test**

Create `rails_backend/test/services/analysis_service_test.rb`:
```ruby
require "test_helper"

class AnalysisServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @food = create(:category, user: @user, name: "Food")
    @travel = create(:category, user: @user, name: "Travel")
  end

  test "summarize totals and buckets by category using the default value (record.amount)" do
    e1 = create(:expense, payer: @user, category: @food, amount: 60.0)
    e2 = create(:expense, payer: @user, category: @travel, amount: 40.0)

    result = AnalysisService.summarize(Expense.where(id: [e1.id, e2.id]))

    assert_equal 100.0, result[:total]
    assert_equal 2, result[:count]
    food_row = result[:by_category].find { |c| c[:category_name] == "Food" }
    assert_equal 60.0, food_row[:amount]
    assert_equal 60.0, food_row[:percent]
  end

  test "summarize accepts a custom value extractor" do
    e1 = create(:expense, payer: @user, category: @food, amount: 100.0)
    other = create(:user)
    create(:expense_split, expense: e1, user: other, amount: 30.0)

    result = AnalysisService.summarize(Expense.where(id: e1.id), value: ->(e) { e.split_for(other.id) })

    assert_equal 30.0, result[:total]
  end

  test "summarize returns 0.0 percent when total is zero" do
    result = AnalysisService.summarize(Expense.none)
    assert_equal 0.0, result[:total]
    assert_equal 0, result[:count]
    assert_equal [], result[:by_category]
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd rails_backend && bin/rails test test/services/analysis_service_test.rb`
Expected: `NameError: uninitialized constant AnalysisService`

- [ ] **Step 3: Implement `AnalysisService`**

Create `rails_backend/app/services/analysis_service.rb`:
```ruby
class AnalysisService
  def self.summarize(scope, value: ->(record) { record.amount })
    records = scope.to_a
    total   = records.sum { |r| value.call(r) }.to_f

    by_category = records.group_by(&:category).map do |category, items|
      amount = items.sum { |r| value.call(r) }.to_f
      {
        category_id:    category&.id.to_s,
        category_name:  category&.name || "Uncategorized",
        category_color: category&.color,
        amount:         amount,
        percent:        total > 0 ? (amount / total * 100).round(1) : 0.0
      }
    end.sort_by { |c| -c[:amount] }

    { total: total, count: records.size, by_category: by_category }
  end
end
```

- [ ] **Step 4: Run the service test to verify it passes**

Run: `cd rails_backend && bin/rails test test/services/analysis_service_test.rb`
Expected: 3 runs, 0 failures, 0 errors.

- [ ] **Step 5: Write a guard test for the personal analysis endpoint**

Create `rails_backend/test/controllers/api/v1/analysis_controller_test.rb`:
```ruby
require "test_helper"

class Api::V1::AnalysisControllerTest < ActionDispatch::IntegrationTest
  test "returns spending and income summaries scoped to the current user, excluding group expenses" do
    user = create(:user)
    category = create(:category, user: user)
    group = create(:group, created_by: user)
    create(:expense, payer: user, category: category, amount: 50.0, date: Date.today)
    create(:expense, payer: user, category: category, amount: 999.0, date: Date.today, group: group)

    get "/api/analysis",
        params: { start_date: Date.today.iso8601, end_date: Date.today.iso8601 },
        headers: auth_header(user)

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 50.0, body["spending"]["total"]
  end
end
```

Run: `cd rails_backend && bin/rails test test/controllers/api/v1/analysis_controller_test.rb`
Expected: PASSES already (this guards existing behavior, written before the refactor below to prove the refactor doesn't change it).

- [ ] **Step 6: Refactor `AnalysisController` to use `AnalysisService`**

Replace the body of `rails_backend/app/controllers/api/v1/analysis_controller.rb` with:
```ruby
module Api
  module V1
    class AnalysisController < ApplicationController
      def show
        expenses = current_user.expenses_paid.where(group_id: nil).includes(:category)
        expenses = expenses.where("date >= ?", params[:start_date]) if params[:start_date].present?
        expenses = expenses.where("date <= ?", params[:end_date]) if params[:end_date].present?

        incomes = current_user.incomes.includes(:category)
        incomes = incomes.where("date >= ?", params[:start_date]) if params[:start_date].present?
        incomes = incomes.where("date <= ?", params[:end_date]) if params[:end_date].present?

        render json: {
          spending: AnalysisService.summarize(expenses),
          income:   AnalysisService.summarize(incomes)
        }
      end
    end
  end
end
```

- [ ] **Step 7: Run both tests again to confirm behavior is unchanged**

Run: `cd rails_backend && bin/rails test test/services/analysis_service_test.rb test/controllers/api/v1/analysis_controller_test.rb`
Expected: all pass, 0 failures, 0 errors.

- [ ] **Step 8: Commit**

```bash
git add rails_backend/app/services/analysis_service.rb rails_backend/app/controllers/api/v1/analysis_controller.rb rails_backend/test/services/analysis_service_test.rb rails_backend/test/controllers/api/v1/analysis_controller_test.rb
git commit -m "refactor(rails): extract AnalysisService.summarize out of AnalysisController"
```

---

## Task 5: New endpoint `GET /api/groups/:id/analysis`

**Files:**
- Modify: `rails_backend/config/routes.rb`
- Modify: `rails_backend/app/controllers/api/v1/groups_controller.rb`
- Test: `rails_backend/test/controllers/api/v1/groups_controller_test.rb`

**Interfaces:**
- Consumes: `AnalysisService.summarize` (Task 4), `Expense#split_for(user_id)` (Task 1), `Expense.with_filters` with `group_id` (Task 3), `Expense.accessible_to(user)` (pre-existing).
- Produces: `GET /api/groups/:id/analysis?start_date=&end_date=` → `{ "total_expense": {total,count,by_category}, "your_share": {total,count,by_category} }`. Consumed by the Flutter side in Task 7.

- [ ] **Step 1: Write the failing controller test**

Create `rails_backend/test/controllers/api/v1/groups_controller_test.rb`:
```ruby
require "test_helper"

class Api::V1::GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = create(:user)
    @bob   = create(:user)
    @group = create(:group, created_by: @alice, members: [@bob])
    @category = create(:category, user: @alice)
  end

  test "group_analysis returns total_expense for the whole group and your_share for the current user" do
    e1 = create(:expense, payer: @alice, category: @category, group: @group, amount: 100.0, split_type: "EQUAL", date: Date.today)
    create(:expense_participant, expense: e1, user: @alice)
    create(:expense_participant, expense: e1, user: @bob)
    create(:expense_split, expense: e1, user: @alice, amount: 50.0)
    create(:expense_split, expense: e1, user: @bob, amount: 50.0)

    get "/api/groups/#{@group.id}/analysis",
        params: { start_date: Date.today.iso8601, end_date: Date.today.iso8601 },
        headers: auth_header(@bob)

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 100.0, body["total_expense"]["total"]
    assert_equal 50.0, body["your_share"]["total"]
  end

  test "group_analysis excludes expenses the current user is not part of from your_share but keeps them in total_expense" do
    charlie = create(:user)
    other_expense = create(:expense, payer: @alice, category: @category, group: @group, amount: 40.0, date: Date.today)
    create(:expense_participant, expense: other_expense, user: @alice)
    create(:expense_participant, expense: other_expense, user: charlie)
    create(:expense_split, expense: other_expense, user: @alice, amount: 20.0)
    create(:expense_split, expense: other_expense, user: charlie, amount: 20.0)

    get "/api/groups/#{@group.id}/analysis",
        params: { start_date: Date.today.iso8601, end_date: Date.today.iso8601 },
        headers: auth_header(@bob)

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal 40.0, body["total_expense"]["total"]
    assert_equal 0.0, body["your_share"]["total"]
  end

  test "group_analysis 404s for a non-member" do
    outsider = create(:user)
    get "/api/groups/#{@group.id}/analysis", headers: auth_header(outsider)
    assert_response :not_found
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd rails_backend && bin/rails test test/controllers/api/v1/groups_controller_test.rb`
Expected: routing error (`No route matches [GET] "/api/groups/.../analysis"`).

- [ ] **Step 3: Add the route**

In `rails_backend/config/routes.rb`, inside the existing `resources :groups do member do ... end end` block, add a line after `get  :expenses, action: :group_expenses`:
```ruby
        get  :analysis, action: :group_analysis
```
So the block reads:
```ruby
    resources :groups, only: [:create, :index, :show] do
      member do
        post :invite
        post :members
        get  :expenses, action: :group_expenses
        get  :analysis, action: :group_analysis
        post :settle
      end
      collection { post :join }
    end
```

- [ ] **Step 4: Add the controller action**

In `rails_backend/app/controllers/api/v1/groups_controller.rb`:

1. Change the `before_action` line to include `:group_analysis`:
```ruby
      before_action :set_group, only: [:show, :invite, :members, :group_expenses, :group_analysis, :settle]
```

2. Add the action (place it directly after `group_expenses`):
```ruby
      def group_analysis
        expenses      = @group.expenses.with_filters(params)
        your_expenses = expenses.merge(Expense.accessible_to(current_user))
        render json: {
          total_expense: AnalysisService.summarize(expenses),
          your_share:    AnalysisService.summarize(your_expenses, value: ->(e) { e.split_for(current_user.id) })
        }
      end

```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd rails_backend && bin/rails test test/controllers/api/v1/groups_controller_test.rb`
Expected: 3 runs, 0 failures, 0 errors.

- [ ] **Step 6: Run the full backend suite**

Run: `cd rails_backend && bin/rails test`
Expected: all green (confirms nothing from Tasks 1-5 broke pre-existing tests).

- [ ] **Step 7: Commit**

```bash
git add rails_backend/config/routes.rb rails_backend/app/controllers/api/v1/groups_controller.rb rails_backend/test/controllers/api/v1/groups_controller_test.rb
git commit -m "feat(rails): add GET /api/groups/:id/analysis for the group expense report"
```

---

## Task 6: Flutter `GroupAnalysisSummary` model

**Files:**
- Create: `square_app/lib/features/groups/data/group_analysis_model.dart`

**Interfaces:**
- Consumes: `AnalysisSide`/`CategoryBreakdown` from `lib/features/transactions/data/analysis_model.dart` (existing, unchanged).
- Produces: `GroupAnalysisSummary { AnalysisSide totalExpense; AnalysisSide yourShare; }` with `GroupAnalysisSummary.fromJson`. Used by Task 7's repository/provider and Task 11's Reports tab.

No test for this step — per Global Constraints, no Dart/Flutter test files are written in this plan.

- [ ] **Step 1: Implement the model**

Create `square_app/lib/features/groups/data/group_analysis_model.dart`:
```dart
import '../../transactions/data/analysis_model.dart';

class GroupAnalysisSummary {
  final AnalysisSide totalExpense;
  final AnalysisSide yourShare;

  GroupAnalysisSummary({required this.totalExpense, required this.yourShare});

  factory GroupAnalysisSummary.fromJson(Map<String, dynamic> json) {
    return GroupAnalysisSummary(
      totalExpense: AnalysisSide.fromJson(json['total_expense'] ?? {}),
      yourShare: AnalysisSide.fromJson(json['your_share'] ?? {}),
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `cd square_app && flutter analyze lib/features/groups/data/group_analysis_model.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add square_app/lib/features/groups/data/group_analysis_model.dart
git commit -m "feat(square_app): add GroupAnalysisSummary model"
```

---

## Task 7: `GroupRepository.getGroupAnalysis` + `groupAnalysisProvider`

**Files:**
- Modify: `square_app/lib/features/groups/data/group_repository.dart`
- Modify: `square_app/lib/features/groups/presentation/groups_provider.dart`

**Interfaces:**
- Consumes: `GroupAnalysisSummary` (Task 6), `groupRepositoryProvider` (existing).
- Produces: `GroupRepository.getGroupAnalysis(groupId, {required startDate, required endDate}) -> Future<GroupAnalysisSummary>`; `groupAnalysisProvider` — `FutureProvider.autoDispose.family<GroupAnalysisSummary, String>` keyed `"groupId|startDate|endDate"`. Used by Task 11's Reports tab.

No new test for this step — per Global Constraints, repository/provider wiring in this codebase is verified via `flutter analyze`, matching how `getGroupExpenses`/`groupExpensesProvider` (its direct siblings) are handled today.

- [ ] **Step 1: Add the repository method**

In `square_app/lib/features/groups/data/group_repository.dart`, add this import at the top (alongside the existing `import 'group_model.dart';`):
```dart
import 'group_analysis_model.dart';
```

Add this method (place it directly after `getGroupExpenses`, before `settle`):
```dart
  Future<GroupAnalysisSummary> getGroupAnalysis(
    String groupId, {
    required String startDate,
    required String endDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.get(
        '/groups/$groupId/analysis',
        queryParameters: {'start_date': startDate, 'end_date': endDate},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return GroupAnalysisSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch group analysis';
    }
  }
```

- [ ] **Step 2: Add the provider**

In `square_app/lib/features/groups/presentation/groups_provider.dart`, add this import at the top:
```dart
import '../data/group_analysis_model.dart';
```

Add this provider (place it directly after `groupExpensesProvider`):
```dart
/// Key shape: "groupId|startDate|endDate".
final groupAnalysisProvider = FutureProvider.autoDispose.family<GroupAnalysisSummary, String>((ref, key) async {
  final parts = key.split('|');
  final groupId = parts[0];
  final startDate = parts[1];
  final endDate = parts[2];
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupAnalysis(groupId, startDate: startDate, endDate: endDate);
});
```

- [ ] **Step 3: Verify**

Run: `cd square_app && flutter analyze lib/features/groups/data/group_repository.dart lib/features/groups/presentation/groups_provider.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add square_app/lib/features/groups/data/group_repository.dart square_app/lib/features/groups/presentation/groups_provider.dart
git commit -m "feat(square_app): add GroupRepository.getGroupAnalysis and groupAnalysisProvider"
```

---

## Task 8: Extract `StatTapTarget`

**Files:**
- Create: `square_app/lib/shared/widgets/stat_tap_target.dart`
- Modify: `square_app/lib/features/transactions/presentation/screens/analysis_screen.dart`

**Interfaces:**
- Produces: `StatTapTarget({label, color, amount, onTap, alignEnd})` — same rendering as the old private `_CashflowTapTarget`, except `onTap` is now nullable (`VoidCallback?`) so a tile can be shown without being tappable (needed by Task 11's non-tappable "Total expense" tile). Used by Task 10's `AnalysisReportView`.

- [ ] **Step 1: Create the shared widget**

Create `square_app/lib/shared/widgets/stat_tap_target.dart`:
```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import 'amount_text.dart';

/// A label + amount that's optionally tappable to drill into that stat's
/// transaction list. Shared between the personal analysis screen
/// (Spending/Income) and the group report (Total expense/Your share).
class StatTapTarget extends StatelessWidget {
  const StatTapTarget({
    super.key,
    required this.label,
    required this.color,
    required this.amount,
    this.onTap,
    this.alignEnd = false,
  });

  final String label;
  final Color color;
  final double amount;
  final bool alignEnd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label.copyWith(color: color)),
          const SizedBox(height: 4),
          // AmountText has its own tap gesture (shows an in-words tooltip) that
          // would otherwise compete with this card's tap-to-drill-down — ignore
          // its pointer so tapping the number always opens the list.
          IgnorePointer(
            child: AmountText(
              amount: amount,
              sign: AmountSign.neutral,
              style: AppTypography.amountLarge,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Remove the private widget and use the shared one in `analysis_screen.dart`**

In `square_app/lib/features/transactions/presentation/screens/analysis_screen.dart`:
1. Add import: `import '../../../../shared/widgets/stat_tap_target.dart';`
2. Delete the `class _CashflowTapTarget extends StatelessWidget { ... }` block entirely (currently lines 169-207).
3. Replace both call sites — `_CashflowTapTarget(` → `StatTapTarget(` (two occurrences, in the `SPENDING`/`INCOME` tiles) — no other argument changes needed, they already pass `onTap`.

- [ ] **Step 3: Verify**

Run: `cd square_app && flutter analyze lib/shared/widgets/stat_tap_target.dart lib/features/transactions/presentation/screens/analysis_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add square_app/lib/shared/widgets/stat_tap_target.dart square_app/lib/features/transactions/presentation/screens/analysis_screen.dart
git commit -m "refactor(square_app): extract StatTapTarget out of AnalysisScreen into shared widgets"
```

---

## Task 9: Extract `SegmentedToggleOption`

**Files:**
- Create: `square_app/lib/shared/widgets/segmented_toggle.dart`
- Modify: `square_app/lib/features/transactions/presentation/screens/analysis_screen.dart`

**Interfaces:**
- Produces: `SegmentedToggleOption({label, selected, onTap})` — same rendering as the old private `_ToggleTab`. Used by Task 10's `AnalysisReportView` (two instances inside a `Row`, exactly as `analysis_screen.dart` already composes them today).

- [ ] **Step 1: Create the shared widget**

Create `square_app/lib/shared/widgets/segmented_toggle.dart`:
```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// One option in a two-way segmented toggle — a label that fills its slot
/// with a solid background when selected. Compose two inside a
/// sunken-background Row to build the full control (see
/// AnalysisReportView) — kept as a single-option widget since that's how
/// the original Spending/Income toggle was already structured.
class SegmentedToggleOption extends StatelessWidget {
  const SegmentedToggleOption({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: selected ? Border.all(color: isDark ? AppColors.lineDark : AppColors.line) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMuted.copyWith(
              color: selected ? ink : inkFaint,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Remove the private widget and use the shared one in `analysis_screen.dart`**

In `square_app/lib/features/transactions/presentation/screens/analysis_screen.dart`:
1. Add import: `import '../../../../shared/widgets/segmented_toggle.dart';`
2. Delete the `class _ToggleTab extends StatelessWidget { ... }` block entirely (currently lines 209-244).
3. Replace both call sites — `_ToggleTab(` → `SegmentedToggleOption(` (two occurrences, Spending/Income toggle tabs).

- [ ] **Step 3: Verify**

Run: `cd square_app && flutter analyze lib/shared/widgets/segmented_toggle.dart lib/features/transactions/presentation/screens/analysis_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add square_app/lib/shared/widgets/segmented_toggle.dart square_app/lib/features/transactions/presentation/screens/analysis_screen.dart
git commit -m "refactor(square_app): extract SegmentedToggleOption out of AnalysisScreen into shared widgets"
```

---

## Task 10: Build `AnalysisReportView`, refactor `AnalysisScreen` onto it

**Files:**
- Create: `square_app/lib/shared/widgets/analysis_report_view.dart`
- Modify: `square_app/lib/features/transactions/presentation/screens/analysis_screen.dart`

**Interfaces:**
- Consumes: `StatTapTarget` (Task 8), `SegmentedToggleOption` (Task 9), `AnalysisSide` (existing, from `lib/features/transactions/data/analysis_model.dart`), `CategoryDonutChart` (existing, from `lib/features/transactions/presentation/widgets/category_donut_chart.dart`).
- Produces: `AnalysisStatTile({label, color, amount, onTap})`, `AnalysisCategorySide({label, side})`, and `AnalysisReportView({primaryTile, secondaryTile, firstSide, secondSide, extra})` — the shared report layout (two stat tiles + a category card with a toggle and donut chart). This is the actual component both the personal Analysis screen and the group Reports tab (Task 11) build on.

This is the component the whole feature's "reuse" requirement centers on — read it carefully before implementing.

- [ ] **Step 1: Create the shared composable**

Create `square_app/lib/shared/widgets/analysis_report_view.dart`:
```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/transactions/data/analysis_model.dart';
import '../../features/transactions/presentation/widgets/category_donut_chart.dart';
import 'app_card.dart';
import 'segmented_toggle.dart';
import 'stat_tap_target.dart';

/// A single stat tile fed into [AnalysisReportView] — e.g. Spending/Income
/// for the personal report, Total expense/Your share for a group report.
/// [onTap] is optional: a tile with no [onTap] renders as a static (non-
/// tappable) stat.
class AnalysisStatTile {
  const AnalysisStatTile({
    required this.label,
    required this.color,
    required this.amount,
    this.onTap,
  });

  final String label;
  final Color color;
  final double amount;
  final VoidCallback? onTap;
}

/// One side of the category breakdown toggle — e.g. "Spending"/"Income", or
/// "Group total"/"Your share".
class AnalysisCategorySide {
  const AnalysisCategorySide({required this.label, required this.side});

  final String label;
  final AnalysisSide side;
}

/// The shared report layout: two stat tiles side by side (plus optional
/// extra content in the same card, e.g. personal analysis's Net Balance
/// row), then a category breakdown card with a toggle between two named
/// sides and a donut chart. Used by both the personal Analysis screen and
/// the group Reports tab — they differ only in which tiles/sides they feed
/// in, not in how any of it renders.
class AnalysisReportView extends StatefulWidget {
  const AnalysisReportView({
    super.key,
    required this.primaryTile,
    required this.secondaryTile,
    required this.firstSide,
    required this.secondSide,
    this.extra,
  });

  final AnalysisStatTile primaryTile;
  final AnalysisStatTile secondaryTile;
  final AnalysisCategorySide firstSide;
  final AnalysisCategorySide secondSide;

  /// Optional content rendered below the stat tiles inside the same card.
  /// Omitted entirely when null (the group report has no equivalent to
  /// personal analysis's Net Balance row).
  final Widget? extra;

  @override
  State<AnalysisReportView> createState() => _AnalysisReportViewState();
}

class _AnalysisReportViewState extends State<AnalysisReportView> {
  bool _showFirstSide = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final selected = _showFirstSide ? widget.firstSide : widget.secondSide;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatTapTarget(
                      label: widget.primaryTile.label,
                      color: widget.primaryTile.color,
                      amount: widget.primaryTile.amount,
                      onTap: widget.primaryTile.onTap,
                    ),
                  ),
                  Expanded(
                    child: StatTapTarget(
                      label: widget.secondaryTile.label,
                      color: widget.secondaryTile.color,
                      amount: widget.secondaryTile.amount,
                      alignEnd: true,
                      onTap: widget.secondaryTile.onTap,
                    ),
                  ),
                ],
              ),
              if (widget.extra != null) ...[
                const SizedBox(height: AppSpacing.lg),
                widget.extra!,
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Categories', style: AppTypography.sectionHeading.copyWith(color: ink)),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: sunken, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedToggleOption(
                        label: widget.firstSide.label,
                        selected: _showFirstSide,
                        onTap: () => setState(() => _showFirstSide = true),
                      ),
                    ),
                    Expanded(
                      child: SegmentedToggleOption(
                        label: widget.secondSide.label,
                        selected: !_showFirstSide,
                        onTap: () => setState(() => _showFirstSide = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CategoryDonutChart(
                key: ValueKey(_showFirstSide),
                categories: selected.side.byCategory,
                total: selected.side.total,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Replace `AnalysisScreen`'s full content with the new file**

Replace the entire contents of `square_app/lib/features/transactions/presentation/screens/analysis_screen.dart` with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/analysis_report_view.dart';
import '../../data/analysis_model.dart';
import '../analysis_provider.dart';
import '../widgets/period_selection.dart';
import '../widgets/period_selector.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  PeriodSelection _period = PeriodSelection.initial();

  String get _rangeKey => '${_period.apiStartDate}|${_period.apiEndDate}';

  @override
  Widget build(BuildContext context) {
    final analysisAsync = ref.watch(analysisProvider(_rangeKey));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(analysisProvider(_rangeKey));
        try {
          await ref.read(analysisProvider(_rangeKey).future);
        } catch (_) {}
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
        children: [
          PeriodSelector(
            selection: _period,
            onChanged: (p) => setState(() => _period = p),
            transactionCount: analysisAsync.value?.transactionCount ?? 0,
          ),
          const SizedBox(height: AppSpacing.lg),
          analysisAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => AppErrorState(
              message: err.toString(),
              onRetry: () => ref.invalidate(analysisProvider(_rangeKey)),
            ),
            data: (summary) => _buildContent(context, summary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AnalysisSummary summary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;

    return AnalysisReportView(
      primaryTile: AnalysisStatTile(
        label: 'SPENDING',
        color: AppColors.negative,
        amount: summary.spending.total,
        onTap: () => _openDrilldown(isSpending: true),
      ),
      secondaryTile: AnalysisStatTile(
        label: 'INCOME',
        color: AppColors.positive,
        amount: summary.income.total,
        onTap: () => _openDrilldown(isSpending: false),
      ),
      firstSide: AnalysisCategorySide(label: 'Spending', side: summary.spending),
      secondSide: AnalysisCategorySide(label: 'Income', side: summary.income),
      extra: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(color: sunken, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Net Balance', style: AppTypography.body.copyWith(color: inkFaint)),
            AmountText(
              amount: summary.netBalance,
              sign: AmountSign.neutral,
              style: AppTypography.cardHeading.copyWith(color: ink),
            ),
          ],
        ),
      ),
    );
  }

  void _openDrilldown({required bool isSpending}) {
    context.push(
      '/transactions/analysis-detail',
      extra: {'isSpending': isSpending, 'period': _period},
    );
  }
}
```

- [ ] **Step 3: Verify**

Run: `cd square_app && flutter analyze lib/shared/widgets/analysis_report_view.dart lib/features/transactions/presentation/screens/analysis_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Manual check — personal Analysis tab renders identically**

Run the app (hot reload if already running), open Transactions → Analysis tab. Confirm: Spending/Income tiles, Net Balance row, Categories card with Spending/Income toggle and donut chart, and tapping a tile still opens the drilldown — all look exactly as before this refactor.

- [ ] **Step 5: Commit**

```bash
git add square_app/lib/shared/widgets/analysis_report_view.dart square_app/lib/features/transactions/presentation/screens/analysis_screen.dart
git commit -m "refactor(square_app): build AnalysisReportView, rebuild AnalysisScreen on top of it"
```

---

## Task 11: Group Details — "Reports" tab

**Files:**
- Modify: `square_app/lib/features/groups/presentation/screens/group_details_screen.dart`

**Interfaces:**
- Consumes: `groupAnalysisProvider` (Task 7), `AnalysisReportView`/`AnalysisStatTile`/`AnalysisCategorySide` (Task 10), `PeriodSelector`/`PeriodSelection` (existing, from `lib/features/transactions/presentation/widgets/`).
- Produces: a 4th tab "Reports" on the group details screen. "Your share" tile pushes `/transactions/analysis-detail` with a `groupId` extra — consumed by Task 12.

- [ ] **Step 1: Add imports**

In `square_app/lib/features/groups/presentation/screens/group_details_screen.dart`, add these imports alongside the existing ones:
```dart
import '../../../../shared/widgets/analysis_report_view.dart';
import '../../../transactions/presentation/widgets/period_selection.dart';
import '../../../transactions/presentation/widgets/period_selector.dart';
```

- [ ] **Step 2: Add a period-selection field**

In `_GroupDetailsScreenState`, add this field alongside `late TabController _tabController;`:
```dart
  PeriodSelection _reportPeriod = PeriodSelection.initial();
```

- [ ] **Step 3: Grow the tab controller to 4 tabs**

Change:
```dart
    _tabController = TabController(length: 3, vsync: this);
```
to:
```dart
    _tabController = TabController(length: 4, vsync: this);
```

- [ ] **Step 4: Add the "Reports" tab and its `TabBarView` content**

Change the `tabs:` list from:
```dart
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
            Tab(text: 'Members'),
          ],
```
to:
```dart
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
            Tab(text: 'Members'),
            Tab(text: 'Reports'),
          ],
```

Change the `TabBarView` children from:
```dart
            children: [
              _buildExpensesTab(context, details),
              _buildBalancesTab(context, details),
              _buildMembersTab(context, details),
            ],
```
to:
```dart
            children: [
              _buildExpensesTab(context, details),
              _buildBalancesTab(context, details),
              _buildMembersTab(context, details),
              _buildReportsTab(context, details),
            ],
```

- [ ] **Step 5: Implement `_buildReportsTab`**

Add this method (place it directly after `_buildMembersTab`):
```dart
  Widget _buildReportsTab(BuildContext context, GroupDetails details) {
    final groupId = details.group.id;
    final rangeKey = '$groupId|${_reportPeriod.apiStartDate}|${_reportPeriod.apiEndDate}';
    final analysisAsync = ref.watch(groupAnalysisProvider(rangeKey));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groupAnalysisProvider(rangeKey));
        try {
          await ref.read(groupAnalysisProvider(rangeKey).future);
        } catch (_) {}
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          PeriodSelector(
            selection: _reportPeriod,
            onChanged: (p) => setState(() => _reportPeriod = p),
            transactionCount: analysisAsync.value?.totalExpense.count ?? 0,
          ),
          const SizedBox(height: AppSpacing.lg),
          analysisAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => AppErrorState(
              message: err.toString(),
              onRetry: () => ref.invalidate(groupAnalysisProvider(rangeKey)),
            ),
            data: (summary) => AnalysisReportView(
              primaryTile: AnalysisStatTile(
                label: 'TOTAL EXPENSE',
                color: AppColors.negative,
                amount: summary.totalExpense.total,
              ),
              secondaryTile: AnalysisStatTile(
                label: 'YOUR SHARE',
                color: AppColors.negative,
                amount: summary.yourShare.total,
                alignEnd: true,
                onTap: () => context.push(
                  '/transactions/analysis-detail',
                  extra: {'isSpending': true, 'period': _reportPeriod, 'groupId': groupId},
                ),
              ),
              firstSide: AnalysisCategorySide(label: 'Group total', side: summary.totalExpense),
              secondSide: AnalysisCategorySide(label: 'Your share', side: summary.yourShare),
            ),
          ),
        ],
      ),
    );
  }

```
Note `primaryTile` (Total expense) has no `onTap` — it renders as a static, non-tappable stat, per the approved design (only "Your share" navigates anywhere).

- [ ] **Step 6: Verify**

Run: `cd square_app && flutter analyze lib/features/groups/presentation/screens/group_details_screen.dart`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add square_app/lib/features/groups/presentation/screens/group_details_screen.dart
git commit -m "feat(square_app): add Reports tab to group details screen"
```

---

## Task 12: Drilldown gains an optional `groupId` filter

**Files:**
- Modify: `square_app/lib/features/transactions/data/transaction_repository.dart`
- Modify: `square_app/lib/features/transactions/presentation/drilldown_provider.dart`
- Modify: `square_app/lib/core/router.dart`
- Modify: `square_app/lib/features/transactions/presentation/screens/transaction_drilldown_screen.dart`

**Interfaces:**
- Consumes: the `group_id` filter added to `Expense.with_filters` (Task 3), the `groupId` extra pushed from Task 11's "Your share" tile.
- Produces: `TransactionRepository.getExpenses(..., groupId: ...)`; `drilldownExpensesProvider` key shape extended to `"startDate|endDate|categoryId|search|groupId"`; `TransactionDrilldownScreen(..., groupId: ...)`.

- [ ] **Step 1: Extend `TransactionRepository.getExpenses`**

In `square_app/lib/features/transactions/data/transaction_repository.dart`, replace the `getExpenses` method with:
```dart
  Future<Map<String, dynamic>> getExpenses(
    String token, {
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
    String? startDate,
    String? endDate,
    String? groupId,
  }) async {
    try {
      final response = await _dio.get(
        '/expenses',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (groupId == null) 'personal_only': 'true',
          if (groupId != null) 'group_id': groupId,
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'category_id': categoryId,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List<dynamic> data =
          response.data['data'] ?? []; // Adjust based on API response structure
      final int total = response.data['total'] ?? 0;
      return {'data': data, 'total': total};
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }
```
This preserves the exact old behavior when `groupId` is omitted (`personal_only: 'true'` sent as before) and switches to group-scoped when it's provided (backend's `Expense.accessible_to` already restricts results to expenses involving the current user).

- [ ] **Step 2: Extend `drilldownExpensesProvider`'s key**

In `square_app/lib/features/transactions/presentation/drilldown_provider.dart`, replace `drilldownExpensesProvider` with:
```dart
/// Key shape: "startDate|endDate|categoryId|search|groupId" — categoryId/search/groupId may be empty.
final drilldownExpensesProvider = FutureProvider.autoDispose.family<List<Expense>, String>((ref, key) async {
  final parts = key.split('|');
  final startDate = parts[0];
  final endDate = parts[1];
  final categoryId = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
  final search = parts.length > 3 ? parts[3] : '';
  final groupId = parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) throw Exception('Not authenticated');

  final repository = ref.watch(transactionRepositoryProvider);
  final result = await repository.getExpenses(
    token,
    page: 1,
    limit: 500,
    search: search,
    categoryId: categoryId,
    startDate: startDate,
    endDate: endDate,
    groupId: groupId,
  );
  return (result['data'] as List).map((e) => Expense.fromJson(e)).toList();
});
```
(`drilldownIncomesProvider` below it is untouched — groups have no income concept.)

- [ ] **Step 3: Pass `groupId` through the route**

In `square_app/lib/core/router.dart`, replace the `analysis-detail` route's builder with:
```dart
              GoRoute(
                path: 'analysis-detail',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return TransactionDrilldownScreen(
                    isSpending: extra['isSpending'] as bool,
                    period: extra['period'] as PeriodSelection,
                    groupId: extra['groupId'] as String?,
                  );
                },
              ),
```

- [ ] **Step 4: Accept and use `groupId` in `TransactionDrilldownScreen`**

In `square_app/lib/features/transactions/presentation/screens/transaction_drilldown_screen.dart`:

1. Replace the constructor and fields:
```dart
class TransactionDrilldownScreen extends ConsumerStatefulWidget {
  const TransactionDrilldownScreen({super.key, required this.isSpending, required this.period, this.groupId});

  final bool isSpending;
  final PeriodSelection period;
  final String? groupId;

  @override
  ConsumerState<TransactionDrilldownScreen> createState() => _TransactionDrilldownScreenState();
}
```

2. Replace the `_key` getter:
```dart
  String get _key =>
      '${widget.period.apiStartDate}|${widget.period.apiEndDate}|${_categoryId ?? ''}|$_searchQuery|${widget.groupId ?? ''}';
```

3. Replace the `AppBar`'s title:
```dart
      appBar: AppBar(title: Text(widget.groupId != null ? 'Your share' : (widget.isSpending ? 'Spending' : 'Income'))),
```

- [ ] **Step 5: Verify**

Run: `cd square_app && flutter analyze lib/features/transactions/data/transaction_repository.dart lib/features/transactions/presentation/drilldown_provider.dart lib/core/router.dart lib/features/transactions/presentation/screens/transaction_drilldown_screen.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add square_app/lib/features/transactions/data/transaction_repository.dart square_app/lib/features/transactions/presentation/drilldown_provider.dart square_app/lib/core/router.dart square_app/lib/features/transactions/presentation/screens/transaction_drilldown_screen.dart
git commit -m "feat(square_app): drilldown accepts an optional groupId filter"
```

---

## Task 13: Full verification pass

**Files:** none (verification only)

- [ ] **Step 1: Run the full backend test suite**

Run: `cd rails_backend && bin/rails test`
Expected: all tests green, including every new test file from Tasks 1-5.

- [ ] **Step 2: Run the full frontend analyze + existing tests**

Run: `cd square_app && flutter analyze && flutter test`
Expected: `No issues found!` and the two pre-existing model tests still pass (no new Dart tests were added in this plan, per Global Constraints).

- [ ] **Step 3: Manual emulator walkthrough**

Launch the app (hot reload if already running against a dev backend pointed at the local Rails server):
1. Transactions → Analysis tab: confirm it renders exactly as before (Spending/Income tiles, Net Balance, category donut + toggle).
2. Open a group that has at least one expense split across members. Confirm a 4th "Reports" tab appears next to Expenses/Balances/Members.
3. Open Reports: confirm "Total expense" and "Your share" tiles render, and the category card's toggle switches between "Group total" and "Your share" breakdowns.
4. Confirm "Total expense" does not respond to taps (no ripple, no navigation).
5. Tap "Your share": confirm it opens the transaction drilldown, titled "Your share", listing only this group's expenses that involve the current user.
6. Change the period selector on the Reports tab and confirm the tiles and drilldown-if-reopened reflect the new range.

- [ ] **Step 4: Fix anything the walkthrough surfaces, then commit if changes were needed**

If Step 3 surfaces a bug, fix it, re-run Steps 1-3, then:
```bash
git add -A
git commit -m "fix(square_app): address issues found in group report manual walkthrough"
```
If no changes were needed, this task ends at Step 3 with nothing to commit.
