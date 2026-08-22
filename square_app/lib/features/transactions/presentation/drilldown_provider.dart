import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../expense/data/expense_model.dart';
import '../data/income_model.dart';
import 'transactions_provider.dart';

/// Key shape: "startDate|endDate|categoryId|search" — categoryId/search may be empty.
final drilldownExpensesProvider = FutureProvider.autoDispose.family<List<Expense>, String>((ref, key) async {
  final parts = key.split('|');
  final startDate = parts[0];
  final endDate = parts[1];
  final categoryId = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
  final search = parts.length > 3 ? parts[3] : '';

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) throw Exception('Not authenticated');

  final repository = ref.watch(transactionRepositoryProvider);
  final result = await repository.getExpenses(
    token,
    page: 1,
    limit: 500,
    search: search,
    categoryId: categoryId,
    startDate: startDate,
    endDate: endDate,
  );
  return (result['data'] as List).map((e) => Expense.fromJson(e)).toList();
});

final drilldownIncomesProvider = FutureProvider.autoDispose.family<List<Income>, String>((ref, key) async {
  final parts = key.split('|');
  final startDate = parts[0];
  final endDate = parts[1];
  final categoryId = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
  final search = parts.length > 3 ? parts[3] : '';

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) throw Exception('Not authenticated');

  final repository = ref.watch(transactionRepositoryProvider);
  final result = await repository.getIncomes(
    token,
    page: 1,
    limit: 500,
    search: search,
    categoryId: categoryId,
    startDate: startDate,
    endDate: endDate,
  );
  return (result['data'] as List).map((e) => Income.fromJson(e)).toList();
});
