# Pull-to-Refresh & Fetch-on-Open Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every list screen supports pull-to-refresh, every detail screen fetches fresh data on open and supports pull-to-refresh.

**Architecture:** Use `FutureProvider.autoDispose.family` for detail providers (auto re-fetches on every open), `ref.invalidate()` + `await ref.read(provider.future)` in `RefreshIndicator.onRefresh` everywhere. Transactions screen additionally invalidates the active tab's provider on tab switch.

**Tech Stack:** Flutter, Riverpod (`FutureProvider.autoDispose.family`, `AsyncNotifierProvider`), GoRouter, Dio.

**Spec:** `docs/superpowers/specs/2026-05-30-pull-to-refresh-design.md`

---

## File Map

| File | Change |
|---|---|
| `lib/features/contacts/presentation/screens/contacts_screen.dart` | Add `RefreshIndicator` wrapping `ListView.builder` |
| `lib/features/expense/presentation/screens/expense_list_screen.dart` | Add `RefreshIndicator` wrapping `CustomScrollView` |
| `lib/features/transactions/presentation/transactions_screen.dart` | Tab switch invalidates provider + `RefreshIndicator` per tab |
| `lib/features/contacts/presentation/screens/contact_detail_screen.dart` | Add `.autoDispose` to `_contactLoansProvider` + `RefreshIndicator` |
| `lib/features/loans/presentation/loan_detail_screen.dart` | Add `.autoDispose` to `_loanDetailProvider` + `RefreshIndicator` in body |
| `lib/features/expense/presentation/expense_provider.dart` | Add `expenseDetailProvider` |
| `lib/features/expense/presentation/screens/expense_detail_screen.dart` | Refactor to accept `expenseId` + watch provider + `RefreshIndicator` |
| `lib/core/router.dart` | Update expense detail routes to use path params, drop `extra` |

All paths are relative to `square_app/`.

---

### Task 1: RefreshIndicator on contacts_screen.dart

**Files:**
- Modify: `lib/features/contacts/presentation/screens/contacts_screen.dart`

- [ ] **Step 1: Add `RefreshIndicator` wrapping the `ListView.builder` in the `data:` branch**

In `contacts_screen.dart`, locate the `data: (list) => list.isEmpty ? ... : ListView.builder(...)` inside `contacts.when(...)`.

Replace the `ListView.builder(...)` call (the non-empty branch) with:

```dart
data: (list) => list.isEmpty
    ? _buildEmpty(context, isDark)
    : RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(contactsProvider);
          await ref.read(contactsProvider.future);
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (_, i) =>
              _ContactTile(contact: list[i], isDark: isDark),
        ),
      ),
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/features/contacts/presentation/screens/contacts_screen.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add square_app/lib/features/contacts/presentation/screens/contacts_screen.dart
git commit -m "feat: pull-to-refresh on contacts list"
```

---

### Task 2: RefreshIndicator on expense_list_screen.dart

**Files:**
- Modify: `lib/features/expense/presentation/screens/expense_list_screen.dart`

- [ ] **Step 1: Wrap `CustomScrollView` in `RefreshIndicator`**

In `expense_list_screen.dart`, the `data: (expenses)` branch returns a `CustomScrollView`. Wrap it with `RefreshIndicator`:

Replace:
```dart
return CustomScrollView(
  slivers: [
    SliverPadding(
```

With:
```dart
return RefreshIndicator(
  onRefresh: () async {
    ref.invalidate(expenseProvider);
    await ref.read(expenseProvider.future);
  },
  child: CustomScrollView(
    slivers: [
      SliverPadding(
```

Close the new `RefreshIndicator` after the closing `);` of `CustomScrollView`. The result:

```dart
return RefreshIndicator(
  onRefresh: () async {
    ref.invalidate(expenseProvider);
    await ref.read(expenseProvider.future);
  },
  child: CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final expense = expenses[index];
            return ExpenseCard(
              expense: expense,
              currentUserId: currentUser?.id ?? '',
              onTap: () {
                context.go('/expenses/${expense.id}', extra: expense);
              },
            );
          }, childCount: expenses.length),
        ),
      ),
    ],
  ),
);
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/features/expense/presentation/screens/expense_list_screen.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add square_app/lib/features/expense/presentation/screens/expense_list_screen.dart
git commit -m "feat: pull-to-refresh on expense list"
```

---

### Task 3: Transactions — tab switch refresh + per-tab RefreshIndicator

**Files:**
- Modify: `lib/features/transactions/presentation/transactions_screen.dart`

- [ ] **Step 1: Add `_invalidateActiveTab()` helper and call it in the tab listener**

In `_TransactionsScreenState`, add this private method (above `initState`):

```dart
void _invalidateActiveTab() {
  switch (_tabController.index) {
    case 0:
      ref.invalidate(transactionsExpensesProvider);
    case 1:
      ref.invalidate(incomesProvider);
    case 2:
      ref.invalidate(investmentsProvider);
    case 3:
      ref.invalidate(loansProvider);
  }
}
```

Then update the `_tabController.addListener` in `initState` to call it:

Replace the existing listener:
```dart
_tabController.addListener(() {
  if (_tabController.index != _selectedIndex) {
    setState(() => _selectedIndex = _tabController.index);
  }
});
```

With:
```dart
_tabController.addListener(() {
  if (_tabController.index != _selectedIndex) {
    setState(() => _selectedIndex = _tabController.index);
    _invalidateActiveTab();
  }
});
```

- [ ] **Step 2: Add `RefreshIndicator` wrapping `ListView.builder` in `TransactionListView`**

In the same file, find `TransactionListView.build()`. Inside the `data: (state)` branch, the `NotificationListener` wraps a `ListView.builder`. Wrap the `ListView.builder` with `RefreshIndicator`:

Replace:
```dart
child: ListView.builder(
  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
  itemCount: flatList.length,
  itemBuilder: (context, i) {
```

With:
```dart
child: RefreshIndicator(
  onRefresh: () async {
    ref.invalidate(provider);
    await ref.read(provider.future);
  },
  child: ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
    itemCount: flatList.length,
    itemBuilder: (context, i) {
```

Add the extra closing `),` after the `ListView.builder`'s closing `),` to close the `RefreshIndicator`.

The full `NotificationListener` child should look like:
```dart
child: RefreshIndicator(
  onRefresh: () async {
    ref.invalidate(provider);
    await ref.read(provider.future);
  },
  child: ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
    itemCount: flatList.length,
    itemBuilder: (context, i) {
      final item = flatList[i];
      if (item == null) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (item is String) return _buildDateHeader(context, item);
      if (item is _IndexedItem<T>) {
        return _buildTransactionCard(context, item.item)
            .animate(
              delay: Duration(
                  milliseconds: min(item.index, 10) * 35),
            )
            .fadeIn(duration: 280.ms)
            .slideY(
              begin: 0.04,
              end: 0,
              duration: 280.ms,
              curve: Curves.easeOut,
            );
      }
      return const SizedBox.shrink();
    },
  ),
),
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/transactions/presentation/transactions_screen.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add square_app/lib/features/transactions/presentation/transactions_screen.dart
git commit -m "feat: tab-switch refresh + pull-to-refresh per tab in transactions"
```

---

### Task 4: autoDispose + RefreshIndicator on contact_detail_screen.dart

**Files:**
- Modify: `lib/features/contacts/presentation/screens/contact_detail_screen.dart`

- [ ] **Step 1: Add `.autoDispose` to `_contactLoansProvider`**

At the top of `contact_detail_screen.dart`, change:

```dart
final _contactLoansProvider =
    FutureProvider.family<ContactLoansResult, String>(
  (ref, contactId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return ref.read(contactsRepositoryProvider).getContactLoans(token, contactId);
  },
);
```

To:

```dart
final _contactLoansProvider =
    FutureProvider.autoDispose.family<ContactLoansResult, String>(
  (ref, contactId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return ref.read(contactsRepositoryProvider).getContactLoans(token, contactId);
  },
);
```

- [ ] **Step 2: Add `RefreshIndicator` wrapping `_ContactDetailBody`**

In `ContactDetailScreen.build()`, the `Scaffold` body is `data.when(...)`. The `data:` branch returns `_ContactDetailBody`. Wrap it with `RefreshIndicator`:

Replace:
```dart
body: data.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text('Error: $e')),
  data: (result) => _ContactDetailBody(
    result: result,
    isDark: isDark,
    onPop: () => context.pop(),
  ),
),
```

With:
```dart
body: data.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text('Error: $e')),
  data: (result) => RefreshIndicator(
    onRefresh: () async {
      ref.invalidate(_contactLoansProvider(contactId));
      await ref.read(_contactLoansProvider(contactId).future);
    },
    child: _ContactDetailBody(
      result: result,
      isDark: isDark,
      onPop: () => context.pop(),
    ),
  ),
),
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/contacts/presentation/screens/contact_detail_screen.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add square_app/lib/features/contacts/presentation/screens/contact_detail_screen.dart
git commit -m "feat: auto-fetch on open + pull-to-refresh on contact detail"
```

---

### Task 5: autoDispose + RefreshIndicator on loan_detail_screen.dart

**Files:**
- Modify: `lib/features/loans/presentation/loan_detail_screen.dart`

- [ ] **Step 1: Add `.autoDispose` to `_loanDetailProvider`**

Change:
```dart
final _loanDetailProvider = FutureProvider.family<LoanDetail, String>(
```

To:
```dart
final _loanDetailProvider = FutureProvider.autoDispose.family<LoanDetail, String>(
```

- [ ] **Step 2: Add `RefreshIndicator` wrapping the `ListView` in `_LoanDetailBodyState`**

In `_LoanDetailBodyState.build()`, the `Scaffold` body is a `ListView(...)`. Wrap it with `RefreshIndicator`:

Replace:
```dart
body: ListView(
  padding: const EdgeInsets.only(bottom: 100),
  children: [
```

With:
```dart
body: RefreshIndicator(
  onRefresh: () async {
    ref.invalidate(_loanDetailProvider(widget.loanId));
    await ref.read(_loanDetailProvider(widget.loanId).future);
  },
  child: ListView(
    padding: const EdgeInsets.only(bottom: 100),
    children: [
```

Add closing `),` after the `ListView`'s closing `],` + `)` to close the `RefreshIndicator`.

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/loans/presentation/loan_detail_screen.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add square_app/lib/features/loans/presentation/loan_detail_screen.dart
git commit -m "feat: auto-fetch on open + pull-to-refresh on loan detail"
```

---

### Task 6: Add `expenseDetailProvider` to expense_provider.dart

**Files:**
- Modify: `lib/features/expense/presentation/expense_provider.dart`

- [ ] **Step 1: Add import for SharedPreferences**

`SharedPreferences` is already used in `ExpenseNotifier._fetchExpenses`. Verify the import exists:
```dart
import 'package:shared_preferences/shared_preferences.dart';
```

If missing, add it. (Check the file — it is likely absent since `ExpenseNotifier` uses it inline. Add if needed.)

- [ ] **Step 2: Add `expenseDetailProvider` at the bottom of the file**

Append after the closing `}` of `ExpenseNotifier`:

```dart
final expenseDetailProvider =
    FutureProvider.autoDispose.family<Expense, String>((ref, id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  return ref.read(expenseRepositoryProvider).getExpenseById(token, id);
});
```

Note: `expenseRepositoryProvider` is defined in `expense_repository.dart` and already imported via `expense_provider.dart`'s existing `import '../data/expense_repository.dart'`.

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/expense/presentation/expense_provider.dart`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add square_app/lib/features/expense/presentation/expense_provider.dart
git commit -m "feat: add expenseDetailProvider (autoDispose.family)"
```

---

### Task 7: Refactor ExpenseDetailScreen to use expenseId + provider

**Files:**
- Modify: `lib/features/expense/presentation/screens/expense_detail_screen.dart`

This is the largest change. The screen currently receives a full `Expense` object. It will now receive an `expenseId: String` and fetch via `expenseDetailProvider`.

- [ ] **Step 1: Change constructor parameter from `expense: Expense` to `expenseId: String`**

Replace:
```dart
class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});
```

With:
```dart
class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;

  const ExpenseDetailScreen({super.key, required this.expenseId});
```

- [ ] **Step 2: Update `_deleteExpense` to use `widget.expenseId`**

In `_deleteExpense()`, replace:
```dart
await ref.read(expenseProvider.notifier).deleteExpense(widget.expense.id);
```

With:
```dart
await ref.read(expenseProvider.notifier).deleteExpense(widget.expenseId);
```

- [ ] **Step 3: Rewrite `build()` to watch `expenseDetailProvider` and add `RefreshIndicator`**

Replace the entire `build()` method with:

```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final currentUserId = ref.watch(authProvider).value?.id;
  final dataAsync = ref.watch(expenseDetailProvider(widget.expenseId));
  final expense = dataAsync.asData?.value;

  return Scaffold(
    appBar: AppBar(
      title: const Text('Expense Details'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          LucideIcons.arrowLeft,
          color: isDark ? Colors.white : Colors.black,
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (expense != null) ...[
          IconButton(
            icon: const Icon(LucideIcons.edit),
            color: isDark ? Colors.white : Colors.black,
            onPressed: () {
              context.push('/transactions/edit', extra: expense);
            },
          ),
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.trash2),
            color: Colors.red,
            onPressed: _deleteExpense,
          ),
        ],
      ],
    ),
    body: dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $e'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(expenseDetailProvider(widget.expenseId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (expense) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expenseDetailProvider(widget.expenseId));
          await ref.read(expenseDetailProvider(widget.expenseId).future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate[800] : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.receipt,
                      size: 48,
                      color: AppColors.primary[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      expense.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.slate[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${expense.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(
                      color: isDark
                          ? AppColors.slate[700]
                          : AppColors.slate[200],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      context,
                      'Date',
                      DateFormat('MMM dd, yyyy').format(expense.date),
                    ),
                    _buildDetailRow(
                        context, 'Category', expense.categoryName),
                    _buildDetailRow(
                      context,
                      'Group',
                      expense.groupName ?? 'Personal',
                    ),
                    _buildDetailRow(
                      context,
                      'Paid By',
                      expense.payerId == currentUserId
                          ? 'You'
                          : (expense.payerName ?? 'Other'),
                    ),
                  ],
                ),
              ),
              if (expense.groupId != null) ...[
                const SizedBox(height: 24),
                _buildSplitBreakdown(context, isDark, expense),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
```

- [ ] **Step 4: Remove the now-unused `expensesAsync` watch and old `expense` resolution at the top of the old `build()`**

The old `build()` had:
```dart
final expensesAsync = ref.watch(expenseProvider);
final expense = expensesAsync.maybeWhen(...);
final isPayer = expense.payerId == currentUser?.id;
String payerName = ...;
```

These are removed. The `isPayer`/`payerName` logic is now inline in the `_buildDetailRow` call for 'Paid By' in Step 3 above.

- [ ] **Step 5: Verify**

Run: `flutter analyze lib/features/expense/presentation/screens/expense_detail_screen.dart`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add square_app/lib/features/expense/presentation/screens/expense_detail_screen.dart
git commit -m "feat: expense detail fetches fresh on open + pull-to-refresh"
```

---

### Task 8: Update router — drop `extra` from expense detail routes

**Files:**
- Modify: `lib/core/router.dart`

There are two expense detail routes, plus one navigation call to update.

- [ ] **Step 1: Update `/transactions/expenses/:id` route**

In `router.dart`, find:
```dart
GoRoute(
  path: 'expenses/:id',
  builder: (context, state) {
    final expense = state.extra as Expense;
    return ExpenseDetailScreen(expense: expense);
  },
),
```

Replace with:
```dart
GoRoute(
  path: 'expenses/:id',
  builder: (context, state) =>
      ExpenseDetailScreen(expenseId: state.pathParameters['id']!),
),
```

- [ ] **Step 2: Update `/expenses/:id` route**

Find:
```dart
GoRoute(
  path: '/expenses/:id',
  builder: (context, state) {
    final expense = state.extra as Expense;
    return ExpenseDetailScreen(expense: expense);
  },
),
```

Replace with:
```dart
GoRoute(
  path: '/expenses/:id',
  builder: (context, state) =>
      ExpenseDetailScreen(expenseId: state.pathParameters['id']!),
),
```

- [ ] **Step 3: Remove unused `Expense` and `Loan` import from router.dart (if now unused)**

Check if `Expense` and `Loan` imports are still needed elsewhere in `router.dart`. The `Loan` import is still used by `/loans/:id/edit` (`state.extra as Loan`). The `Expense` import was only used for the two expense detail routes. Remove it if unused:

```dart
// Remove this line if Expense is no longer referenced:
import '../../features/expense/data/expense_model.dart';
```

Run `flutter analyze` — it will tell you if the import is unused.

- [ ] **Step 4: Remove `extra: expense` from expense navigation in `expense_list_screen.dart`**

In `expense_list_screen.dart`, find:
```dart
onTap: () {
  context.go('/expenses/${expense.id}', extra: expense);
},
```

Replace with:
```dart
onTap: () {
  context.go('/expenses/${expense.id}');
},
```

- [ ] **Step 5: Remove `extra: item` from expense navigation in `transactions_screen.dart`**

In `transactions_screen.dart`, find:
```dart
onTap: () =>
    context.push('/transactions/expenses/${item.id}', extra: item),
```

Replace with:
```dart
onTap: () => context.push('/transactions/expenses/${item.id}'),
```

- [ ] **Step 6: Verify whole app**

Run: `flutter analyze lib/`
Expected: No issues.

Run: `flutter build apk --debug` (or `flutter run`) to verify the app builds and all navigation works.

- [ ] **Step 7: Commit**

```bash
git add square_app/lib/core/router.dart \
        square_app/lib/features/expense/presentation/screens/expense_list_screen.dart \
        square_app/lib/features/transactions/presentation/transactions_screen.dart
git commit -m "feat: update routes — expense detail uses path param, drop extra"
```
