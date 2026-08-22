# Group Expense Report Design

**Date:** 2026-08-22
**Status:** Approved

## Goal

Each group gets an expense report page equivalent to the existing personal
"Analysis" tab (period selector, stat tiles, category breakdown donut), but
scoped to the group. Two stats replace personal's Spending/Income: **Total
expense** (the group's total for the period) and **Your share** (the
current user's portion). Tapping "Your share" opens the existing transaction
drilldown list, filtered to this group and this user.

The personal Analysis screen and the new group report must share their UI
components rather than duplicate them — the "shared/reusable" requirement is
the point of this feature, not an afterthought.

## Backend (Rails)

### `Expense#split_for(user)`

New instance method on `Expense`, the single source of truth for "how much
of this expense belongs to `user`":

```ruby
def split_for(user)
  split = expense_splits.find { |s| s.user_id == user.id }
  return split.amount.to_f if split
  return 0.0 unless expense_participants.any? { |p| p.user_id == user.id }
  amount / expense_participants.size.to_f
end
```

`expense_splits.amount` is always a dollar amount regardless of
`split_type` (`ExpenseSplitCalculator` already resolves `PERCENT` to
dollars at creation time), so no special-casing by `split_type` is needed
here.

### Fix `DebtSettlementService`

`DebtSettlementService.compute` currently reimplements this math inline and
incorrectly re-divides `PERCENT` splits by 100 (treating `expense_splits.amount`
as a percentage, which it isn't). Replace that inline block with
`exp.split_for(user)` for each participant. Balances are computed live on
every request (not stored), so this is a forward-only correction — no
migration required. Any group currently using `PERCENT` splits will see its
balances change to the correct values on next load.

### `Expense.with_filters`

Add an optional `group_id` filter alongside the existing
`category_id`/`start_date`/`end_date`/`search`:

```ruby
scope = scope.where(group_id: params[:group_id]) if params[:group_id].present?
```

### `AnalysisService` (extracted)

Move `AnalysisController#summarize` into `app/services/analysis_service.rb`,
generalized to accept a value extractor:

```ruby
class AnalysisService
  def self.summarize(scope, value: ->(record) { record.amount })
    records = scope.to_a
    total = records.sum { |r| value.call(r) }
    by_category = records.group_by(&:category).map do |category, recs|
      amt = recs.sum { |r| value.call(r) }
      { category_id: category&.id, category_name: category&.name,
        category_color: category&.color, amount: amt,
        percent: total.zero? ? 0 : (amt / total * 100).round(1) }
    end.sort_by { |c| -c[:amount] }
    { total: total, count: records.size, by_category: by_category }
  end
end
```

`AnalysisController#show` (personal `/api/analysis`) is updated to call
`AnalysisService.summarize(scope)` in place of its private method — behavior
unchanged (still `current_user.expenses_paid.where(group_id: nil)` for
spending, `current_user.incomes` for income).

### New endpoint: `GET /api/groups/:id/analysis`

`config/routes.rb`, inside the existing `resources :groups do member do ... end`
block:

```ruby
get :analysis, action: :group_analysis
```

`Api::V1::GroupsController#group_analysis` (scoped via the existing
`set_group` before_action, so 404s for non-members exactly like
`group_expenses`):

```ruby
def group_analysis
  expenses = @group.expenses.with_filters(params)
  total_expense = AnalysisService.summarize(expenses)
  your_expenses = expenses.merge(Expense.accessible_to(current_user))
  your_share = AnalysisService.summarize(your_expenses, value: ->(e) { e.split_for(current_user) })
  render json: { total_expense: total_expense, your_share: your_share }
end
```

`your_share` is scoped through `Expense.accessible_to(current_user)` — the
same "payer OR participant" criterion the drilldown list endpoint
(`Api::V1::ExpensesController#index`) already uses. Using the identical
criterion for both the aggregate and its drilldown keeps them consistent by
construction: whatever expenses sum into "your share" are exactly the
expenses that appear when you tap into it.

Response shape mirrors the personal endpoint structurally
(`{ spending, income }` → `{ total_expense, your_share }`), each side
`{ total, count, by_category }`.

### Drilldown list: group scoping

`Api::V1::ExpensesController#index` already scopes via
`Expense.accessible_to(current_user)` (payer OR participant) — no change
needed there beyond the new `group_id` filter added to `with_filters`
above. Passing `group_id` + relying on existing `accessible_to` scoping is
sufficient to get "expenses in this group involving me."

## Frontend (Flutter)

### Data layer

- `lib/features/groups/data/group_analysis_model.dart`: `GroupAnalysisSummary`
  with `totalExpense`/`yourShare` fields, both typed as the existing
  `AnalysisSide` (from `lib/features/transactions/data/analysis_model.dart`,
  reused as-is — no new value classes).
- `GroupRepository.getGroupAnalysis(token, groupId, {startDate, endDate})` →
  `GET /groups/:id/analysis`.
- `groupAnalysisProvider` — `FutureProvider.autoDispose.family<GroupAnalysisSummary, String>`,
  key `"groupId|startDate|endDate"`, mirroring the existing
  `analysisProvider`/`groupExpensesProvider` composite-key convention.
- `TransactionRepository.getExpenses` gains an optional `groupId` param
  (→ `group_id` query param); `drilldownExpensesProvider`'s composite key
  extends to include it (empty string when absent, matching the existing
  `categoryId` convention).
- `/transactions/analysis-detail` route's `extra` map gains an optional
  `groupId` key (no route path change). `TransactionDrilldownScreen` reads
  it and passes it through to the provider when present; the app bar title
  reflects the group context (e.g. "Your share" instead of "Spending").

### Component extraction (the reuse requirement)

- `_CashflowTapTarget` (private, `analysis_screen.dart`) → `StatTapTarget`,
  moved to `lib/shared/widgets/stat_tap_target.dart`. Same
  label/amount/onTap shape, no behavior change.
- `_ToggleTab` (private, `analysis_screen.dart`) → a generic two-way
  segmented toggle, moved to `lib/shared/widgets/`.
- New `AnalysisReportView` composable (period selector + two `StatTapTarget`s
  + toggle/donut category section), built from the two extracted widgets
  plus the existing `PeriodSelector` and `CategoryDonutChart` (already
  generic, left in place).
- `AnalysisScreen` (personal) is refactored to build its existing UI on top
  of `AnalysisReportView` — behavior-preserving refactor, not a rewrite.
- Group report is built on top of the same `AnalysisReportView`, fed
  `total_expense`/`your_share` instead of `spending`/`income`. This
  component is the actual shared/reusable piece the two screens have in
  common.

### Group Details screen

- `group_details_screen.dart`: `TabController` grows from 3 tabs to 4,
  adding `Tab(text: 'Reports')` alongside Expenses/Balances/Members.
- New `_buildReportsTab` renders `AnalysisReportView` wired to
  `groupAnalysisProvider(groupId)`, with tiles "Total expense" (static,
  not tappable) and "Your share" (tappable, pushes
  `/transactions/analysis-detail` with `{isSpending: true, period, groupId}`).

## Out of Scope

- Making "Total expense" tappable (only "Your share" was requested to
  navigate anywhere).
- Any net-balance-style row on the group report (personal analysis has a
  Net Balance row; groups have no equivalent concept here — balances/debts
  already live on the existing Balances tab).
- Backend pagination/perf work for very large groups — `@group.expenses`
  is loaded in full for aggregation, matching the existing personal
  `/api/analysis` approach.
- Physically relocating `PeriodSelector`/`CategoryDonutChart` into
  `lib/shared/widgets/` — they're already generic enough to reuse from
  their current location under `transactions/presentation/widgets/`.
