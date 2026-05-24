import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../expense/data/expense_model.dart';
import '../data/income_model.dart';
import '../data/investment_model.dart';
import '../data/loan_model.dart';
import '../presentation/transactions_provider.dart';
import '../../../../shared/widgets/add_entry_bottom_sheet.dart';
import 'widgets/premium_transaction_card.dart';

class _TabInfo {
  final String label;
  final Color color;
  const _TabInfo(this.label, this.color);
}

const _tabs = [
  _TabInfo('Expenses', Color(0xFFef4444)),
  _TabInfo('Income', Color(0xFF22c55e)),
  _TabInfo('Invest', Color(0xFF8b5cf6)),
  _TabInfo('Loans', Color(0xFFf59e0b)),
];

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _selectedIndex) {
        setState(() => _selectedIndex = _tabController.index);
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
    final activeColor = _tabs[_selectedIndex].color;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF7F7F7),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddEntryBottomSheet.show(context),
        backgroundColor: activeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.plus, size: 22),
      ),
      appBar: AppBar(
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        backgroundColor: isDark ? Colors.black : const Color(0xFFF7F7F7),
        elevation: 0,
        title: Text(
          'Transactions',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // Custom type-colored tab bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: List.generate(4, (i) {
                final tab = _tabs[i];
                final isSelected = _selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tab.color.withOpacity(isDark ? 0.18 : 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isSelected
                                ? tab.color
                                : (isDark
                                    ? const Color(0xFF444444)
                                    : const Color(0xFFBBBBBB)),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12.5,
                          ),
                          child: Text(tab.label),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TransactionListView<Expense>(
                    provider: transactionsExpensesProvider),
                TransactionListView<Income>(provider: incomesProvider),
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
  final AsyncNotifierProvider<GenericTransactionNotifier<T>, TransactionState<T>>
      provider;

  const TransactionListView({super.key, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (state) {
        if (state.items.isEmpty) return _buildEmptyState(context);

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
            if (state.hasMore &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200) {
              notifier.loadMore();
            }
            return true;
          },
          child: ListView.builder(
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
        );
      },
    );
  }

  Widget _buildDateHeader(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
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

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF111111)
                  : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              LucideIcons.inbox,
              size: 30,
              color:
                  isDark ? const Color(0xFF333333) : const Color(0xFFCCCCCC),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              color:
                  isDark ? const Color(0xFF444444) : const Color(0xFFBBBBBB),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
        onTap: () =>
            context.push('/transactions/expenses/${item.id}', extra: item),
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
      final isLent = item.type == 'LENT';
      return PremiumTransactionCard(
        title: item.counterpartyName,
        subtitle: item.status,
        amount: item.amount,
        date: item.date,
        type: TransactionType.loan,
        category: isLent ? 'Lent' : 'Borrowed',
        isPositive: isLent,
        onTap: () {},
      );
    }
    return const SizedBox.shrink();
  }
}
