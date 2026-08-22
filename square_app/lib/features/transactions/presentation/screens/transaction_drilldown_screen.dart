import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/category_picker_sheet.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../expense/presentation/widgets/expense_card.dart';
import '../drilldown_provider.dart';
import '../widgets/period_selection.dart';
import '../widgets/premium_transaction_card.dart';

class TransactionDrilldownScreen extends ConsumerStatefulWidget {
  const TransactionDrilldownScreen({super.key, required this.isSpending, required this.period, this.groupId});

  final bool isSpending;
  final PeriodSelection period;
  final String? groupId;

  @override
  ConsumerState<TransactionDrilldownScreen> createState() => _TransactionDrilldownScreenState();
}

class _TransactionDrilldownScreenState extends ConsumerState<TransactionDrilldownScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  String? _categoryId;
  String? _categoryName;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
    });
  }

  String get _key =>
      '${widget.period.apiStartDate}|${widget.period.apiEndDate}|${_categoryId ?? ''}|$_searchQuery|${widget.groupId ?? ''}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final line = isDark ? AppColors.lineDark : AppColors.line;

    return Scaffold(
      appBar: AppBar(title: Text(widget.groupId != null ? 'Your share' : (widget.isSpending ? 'Spending' : 'Income'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: Container(
              decoration: BoxDecoration(
                color: sunken,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: line),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: AppTypography.body.copyWith(color: ink),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: AppTypography.body.copyWith(color: inkFaint),
                  prefixIcon: Icon(Icons.search, size: 18, color: inkFaint),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, size: 16, color: inkFaint),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                _FilterChip(label: widget.period.label),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: _categoryName ?? 'All categories',
                  onTap: () => CategoryPickerSheet.show(
                    context,
                    selectedId: _categoryId,
                    appliesTo: widget.isSpending ? 'expense' : 'income',
                    onSelected: (id, name) => setState(() {
                      _categoryId = id;
                      _categoryName = name;
                    }),
                  ),
                  onClear: _categoryId != null
                      ? () => setState(() {
                            _categoryId = null;
                            _categoryName = null;
                          })
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.isSpending ? _buildExpenseList(context) : _buildIncomeList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context) {
    final expensesAsync = ref.watch(drilldownExpensesProvider(_key));
    final currentUser = ref.watch(authProvider).value;

    return expensesAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 6,
        itemBuilder: (_, __) => const AppSkeletonRow(),
      ),
      error: (err, _) => AppErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(drilldownExpensesProvider(_key)),
      ),
      data: (expenses) {
        if (expenses.isEmpty) {
          return AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses',
            message: 'Nothing matches this filter.',
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return ExpenseCard(
              expense: expense,
              currentUserId: currentUser?.id ?? '',
              onTap: () => context.push('/transactions/expenses/${expense.id}'),
            );
          },
        );
      },
    );
  }

  Widget _buildIncomeList(BuildContext context) {
    final incomesAsync = ref.watch(drilldownIncomesProvider(_key));

    return incomesAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 6,
        itemBuilder: (_, __) => const AppSkeletonRow(),
      ),
      error: (err, _) => AppErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(drilldownIncomesProvider(_key)),
      ),
      data: (incomes) {
        if (incomes.isEmpty) {
          return AppEmptyState(
            icon: Icons.trending_up,
            title: 'No income',
            message: 'Nothing matches this filter.',
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: incomes.length,
          itemBuilder: (context, index) {
            final income = incomes[index];
            return PremiumTransactionCard(
              title: income.source,
              subtitle: income.categoryName,
              amount: income.amount,
              date: income.date,
              type: TransactionType.income,
              category: income.description.isNotEmpty ? income.description : null,
              isPositive: true,
              onTap: () {},
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.onTap, this.onClear});

  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final line = isDark ? AppColors.lineDark : AppColors.line;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: sunken,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.bodyMuted.copyWith(color: ink)),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: inkFaint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
