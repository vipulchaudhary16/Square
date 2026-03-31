import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../expense_provider.dart';
import '../widgets/expense_card.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseState = ref.watch(expenseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(authProvider).value;

    return Scaffold(
      body: expenseState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (expenses) {
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.receipt,
                    size: 64,
                    color: isDark ? AppColors.slate[700] : AppColors.slate[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses yet',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.slate[500]
                          : AppColors.slate[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/expenses/add'),
        backgroundColor: AppColors.primary[600],
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }
}
