# Pull-to-Refresh & Fetch-on-Open Design

**Date:** 2026-05-30
**Status:** Approved

## Goal

Every list screen supports pull-to-refresh. Every detail screen fetches fresh data from the server each time it is opened, and also supports pull-to-refresh.

## Approach

Use `FutureProvider.family.autoDispose` for all detail screens. The `.autoDispose` modifier destroys the provider when the screen is popped, so navigating back and returning always triggers a fresh fetch — no imperative refresh logic in `initState` needed.

List screens keep their existing `AsyncNotifierProvider`. Pull-to-refresh calls `ref.invalidate()` on the notifier, which re-runs `build()` and triggers a new network fetch.

This pattern is already established in `group_details_screen.dart` and is extended uniformly across the app.

## Data Flow

```
FutureProvider.family.autoDispose(id)
  → Repository.fetchById(id)
  → AsyncValue.when(
      loading: CircularProgressIndicator,
      error: ErrorView + Retry button,
      data: screen content,
    )

RefreshIndicator.onRefresh:
  → ref.invalidate(provider(id))
  → await ref.read(provider(id).future)
```

## Screens Affected

### Detail Screens (new providers required)

| Screen | New Provider | Repository Method |
|---|---|---|
| `contact_detail_screen.dart` | `contactDetailProvider(id)` | `ContactsRepository.fetchById(id)` |
| `expense_detail_screen.dart` | `expenseDetailProvider(id)` | `ExpenseRepository.fetchById(id)` |
| `loan_detail_screen.dart` | `loanDetailProvider(id)` | `LoanRepository.fetchById(id)` |
| `group_details_screen.dart` | already implemented | already done ✓ |

### List Screens (RefreshIndicator only)

| Screen | Provider to Invalidate |
|---|---|
| `contacts_screen.dart` | `contactsProvider` |
| `expense_list_screen.dart` | `expenseProvider` |
| `groups_screen.dart` | `groupsProvider` |
| `transactions_screen.dart` | 4 tab providers (see below) |

### Transactions Screen — Tab Refresh

The transactions screen has 4 tabs, each backed by its own `AsyncNotifierProvider`:

| Tab | Provider |
|---|---|
| Expenses | `transactionsExpensesProvider` |
| Income | `incomesProvider` |
| Invest | `investmentsProvider` |
| Loans | `loansProvider` |

Two refresh triggers for transactions:

1. **Pull-to-refresh per tab** — `TransactionListView` wraps its `ListView.builder` in a `RefreshIndicator`. `onRefresh` invalidates the relevant provider and awaits its future.
2. **Tab switch refresh** — The `TabController` listener in `TransactionsScreen` calls `ref.invalidate(activeTabProvider)` when `_selectedIndex` changes, so switching to a tab always re-fetches its data.

## Navigation Changes

Detail screens currently receive full objects via GoRouter's `extra` parameter. Since all detail screens now always fetch fresh data by ID, the `extra` parameter is dropped. Screens only need the ID from the path parameter (`:id`), which is already defined in the router.

## Repository Changes

Add `fetchById(id)` methods to repositories that currently only have list-fetch:
- `ContactsRepository` — fetch single contact + their loans
- `ExpenseRepository` — fetch single expense by ID
- `LoanRepository` — fetch single loan by ID

Groups repository likely already has a single-fetch method (used by existing provider).

## Loading & Error States

- **Loading:** Centered `CircularProgressIndicator` on detail screen open. `RefreshIndicator` native spinner on pull-to-refresh for both list and detail screens.
- **Error:** `AsyncValue.error` renders an error message + "Retry" button that calls `ref.invalidate(provider)`.
- **Pull-to-refresh error:** Spinner dismisses, existing error state shows. No crash.

## Out of Scope

- Auto-refresh of list screen when returning from a detail screen after an edit. User can pull-to-refresh the list manually.
- WebSocket or polling-based live updates.
- Offline caching or optimistic updates.
