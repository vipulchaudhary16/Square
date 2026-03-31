import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../expense/data/expense_model.dart';
import '../data/income_model.dart';
import '../data/investment_model.dart';
import '../data/loan_model.dart';
import '../presentation/transactions_provider.dart';
import '../../../../shared/widgets/add_entry_bottom_sheet.dart';
import 'widgets/premium_transaction_card.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }



  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddEntryBottomSheet.show(context),
        label: const Text('Add Entry'),
        icon: const Icon(LucideIcons.plus),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      appBar: AppBar(
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark 
            ? SystemUiOverlayStyle.light 
            : SystemUiOverlayStyle.dark,
        title: Text(
          'Transactions',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Custom Tab Selector
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Income'),
                Tab(text: 'Investments'),
                Tab(text: 'Loans'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TransactionListView<Expense>(
                  provider: transactionsExpensesProvider,
                ),
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

class TransactionListView<T> extends ConsumerWidget {
  final AsyncNotifierProvider<
    GenericTransactionNotifier<T>,
    TransactionState<T>
  >
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
        if (state.items.isEmpty) {
          return const Center(child: Text('No transactions found'));
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (state.hasMore &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 200) {
              notifier.loadMore();
            }
            return true;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.items.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final item = state.items[index];
              return _buildTransactionCard(context, item);
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard(BuildContext context, T item) {
    if (item is Expense) {
      return PremiumTransactionCard(
        title: item.description.isNotEmpty ? item.description : 'Expense',
        subtitle: item.category, // Tag on right
        amount: item.amount,
        date: item.date,
        type: TransactionType.expense,
        category: null, // Removed dot text since category is now tag
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
        category: item.description,
        isPositive: true,
        // Add specific income detail route if needed, for now placeholder or generic
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
        subtitle: item.status, // "Settled" / "Pending"
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
