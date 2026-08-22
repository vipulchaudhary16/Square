import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/expense_model.dart';
import '../data/expense_repository.dart';

final expenseProvider = AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(
  ExpenseNotifier.new,
);

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return ref.read(expenseRepositoryProvider).getExpenses();
  }

  Future<void> addExpense(Map<String, dynamic> expenseData) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(expenseRepositoryProvider);
      await repository.createExpense(expenseData);
      return repository.getExpenses();
    });
  }

  Future<void> updateExpense(
    String id,
    Map<String, dynamic> expenseData,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(expenseRepositoryProvider);
      await repository.updateExpense(id, expenseData);
      return repository.getExpenses();
    });
  }

  Future<void> deleteExpense(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(expenseRepositoryProvider);
      await repository.deleteExpense(id);
      return repository.getExpenses();
    });
  }
}

final expenseDetailProvider = FutureProvider.autoDispose
    .family<Expense, String>((ref, id) async {
      return ref.read(expenseRepositoryProvider).getExpenseById(id);
    });
