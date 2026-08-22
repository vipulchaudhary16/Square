import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/buttons/button_shell.dart';
import '../../expense/data/expense_model.dart';
import '../data/income_model.dart';
import '../data/investment_model.dart';
import '../data/loan_model.dart';
import '../presentation/transactions_provider.dart';
import '../../../../shared/widgets/add_entry_bottom_sheet.dart';
import '../../../../shared/widgets/menu_button.dart';
import 'screens/analysis_screen.dart';
import 'widgets/premium_transaction_card.dart';

const _tabLabels = ['Analysis', 'Invest', 'Loans'];

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  void _invalidateActiveTab() {
    switch (_tabController.index) {
      case 1:
        ref.invalidate(investmentsProvider);
      case 2:
        ref.invalidate(loansProvider);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _selectedIndex && !_tabController.indexIsChanging) {
        setState(() => _selectedIndex = _tabController.index);
        _invalidateActiveTab();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final onInk = isDark ? AppColors.surfaceSunkenDark : AppColors.surface;
    final bg = isDark ? AppColors.surfaceSunkenDark : AppColors.surfaceSunken;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddEntryBottomSheet.show(context),
        backgroundColor: ink,
        foregroundColor: onInk,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        child: const Icon(Icons.add, size: 22),
      ),
      appBar: AppBar(
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        backgroundColor: bg,
        elevation: 0,
        title: Text('Transactions', style: AppTypography.screenTitle.copyWith(color: ink)),
        actions: const [MenuButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
            child: Row(
              children: List.generate(3, (i) {
                final isSelected = _selectedIndex == i;
                return Expanded(
                  child: ButtonShell(
                    onTap: () => _tabController.animateTo(i),
                    borderRadius: AppRadius.sm,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected ? ink : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: AppTypography.bodyMuted.copyWith(
                            color: isSelected ? onInk : (isDark ? AppColors.inkFaintDark : AppColors.inkFaint),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          child: Text(_tabLabels[i]),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const AnalysisScreen(),
                TransactionListView<Investment>(provider: investmentsProvider),
                TransactionListView<Loan>(provider: loansProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexedItem<T> {
  final T item;
  final int index;
  const _IndexedItem(this.item, this.index);
}

class TransactionListView<T> extends ConsumerWidget {
  final AsyncNotifierProvider<GenericTransactionNotifier<T>, TransactionState<T>> provider;

  const TransactionListView({super.key, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return stateAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 100),
        itemCount: 6,
        itemBuilder: (_, _) => const AppSkeletonRow(),
      ),
      error: (err, stack) => AppErrorState(message: '$err', onRetry: () => ref.invalidate(provider)),
      data: (state) {
        if (state.items.isEmpty) {
          return AppEmptyState(icon: Icons.inbox_outlined, title: 'No transactions yet');
        }

        // Group by date with stable card indices for animation delay
        final grouped = _groupByDate(state.items);
        final flatList = <dynamic>[];
        var cardIndex = 0;
        for (final entry in grouped.entries) {
          flatList.add(entry.key); // String = date header
          for (final item in entry.value) {
            flatList.add(_IndexedItem<T>(item, cardIndex));
            cardIndex++;
          }
        }
        if (state.hasMore) flatList.add(null);

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (state.hasMore && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              notifier.loadMore();
            }
            return true;
          },
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(provider);
              await ref.read(provider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, 100),
              itemCount: flatList.length,
              itemBuilder: (context, i) {
                final item = flatList[i];
                if (item == null) {
                  return const Center(
                    child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()),
                  );
                }
                if (item is String) return _buildDateHeader(context, item);
                if (item is _IndexedItem<T>) {
                  return _buildTransactionCard(context, item.item)
                      .animate(delay: Duration(milliseconds: min(item.index, 10) * 35))
                      .fadeIn(duration: 280.ms)
                      .slideY(begin: 0.04, end: 0, duration: 280.ms, curve: Curves.easeOut);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, AppSpacing.lg, 4, AppSpacing.sm),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.label.copyWith(color: isDark ? AppColors.inkFaintDark : AppColors.inkFaint),
      ),
    );
  }

  Map<String, List<T>> _groupByDate(List<T> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<T>>{};

    for (final item in items) {
      final date = _getDate(item);
      final day = DateTime(date.year, date.month, date.day);
      final String label;
      if (day == today) {
        label = 'Today';
      } else if (day == yesterday) {
        label = 'Yesterday';
      } else if (now.year == date.year) {
        label = DateFormat('MMMM d').format(date);
      } else {
        label = DateFormat('MMMM d, y').format(date);
      }
      (groups[label] ??= []).add(item);
    }
    return groups;
  }

  DateTime _getDate(T item) {
    if (item is Expense) return item.date;
    if (item is Income) return item.date;
    if (item is Investment) return item.date;
    if (item is Loan) return item.date;
    return DateTime.now();
  }

  Widget _buildTransactionCard(BuildContext context, T item) {
    if (item is Expense) {
      return PremiumTransactionCard(
        title: item.description.isNotEmpty ? item.description : 'Expense',
        subtitle: item.categoryName,
        amount: item.amount,
        date: item.date,
        type: TransactionType.expense,
        category: null,
        isPositive: false,
        onTap: () => context.push('/transactions/expenses/${item.id}'),
      );
    } else if (item is Income) {
      return PremiumTransactionCard(
        title: item.source,
        subtitle: 'Income',
        amount: item.amount,
        date: item.date,
        type: TransactionType.income,
        category: item.description.isNotEmpty ? item.description : null,
        isPositive: true,
        onTap: () {},
      );
    } else if (item is Investment) {
      final isProfit = item.currentValue >= item.amountInvested;
      return PremiumTransactionCard(
        title: item.description,
        subtitle: item.type,
        amount: item.currentValue,
        date: item.date,
        type: TransactionType.investment,
        category: null,
        isPositive: isProfit,
        onTap: () {},
      );
    } else if (item is Loan) {
      final isLent = item.direction == 'lent';
      return PremiumTransactionCard(
        title: item.contactName,
        subtitle: item.status,
        amount: item.amount,
        date: item.date,
        type: TransactionType.loan,
        category: isLent ? 'Lent' : 'Borrowed',
        isPositive: isLent,
        onTap: () => context.push('/loans/${item.id}'),
      );
    }
    return const SizedBox.shrink();
  }
}
