import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/expense_model.dart';
import '../data/expense_repository.dart';

final expenseProvider = AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(
  ExpenseNotifier.new,
);

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return _fetchExpenses();
  }

  Future<List<Expense>> _fetchExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return [];
    }

    final repository = ref.read(expenseRepositoryProvider);
    return repository.getExpenses(token);
  }

  Future<void> addExpense(Map<String, dynamic> expenseData) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Not authenticated');

      final repository = ref.read(expenseRepositoryProvider);
      await repository.createExpense(token, expenseData);

      // refetch to update list
      return _fetchExpenses();
    });
  }

  Future<void> updateExpense(
    String id,
    Map<String, dynamic> expenseData,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Not authenticated');

      final repository = ref.read(expenseRepositoryProvider);
      await repository.updateExpense(token, id, expenseData);

      return _fetchExpenses();
    });
  }

  Future<void> deleteExpense(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Not authenticated');

      final repository = ref.read(expenseRepositoryProvider);
      await repository.deleteExpense(token, id);

      return _fetchExpenses();
    });
  }
}
