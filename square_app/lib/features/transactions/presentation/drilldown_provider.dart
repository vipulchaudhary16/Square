import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expense/data/expense_model.dart';
import '../data/income_model.dart';
import 'transactions_provider.dart';

/// Key shape: "startDate|endDate|categoryId|search|groupId" — categoryId/search/groupId may be empty.
final drilldownExpensesProvider = FutureProvider.autoDispose
    .family<List<Expense>, String>((ref, key) async {
      final parts = key.split('|');
      final startDate = parts[0];
      final endDate = parts[1];
      final categoryId = parts.length > 2 && parts[2].isNotEmpty
          ? parts[2]
          : null;
      final search = parts.length > 3 ? parts[3] : '';
      final groupId = parts.length > 4 && parts[4].isNotEmpty
          ? parts[4]
          : null;

      final repository = ref.watch(transactionRepositoryProvider);
      final result = await repository.getExpenses(
        page: 1,
        limit: 500,
        search: search,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
        groupId: groupId,
      );
      return (result['data'] as List).map((e) => Expense.fromJson(e)).toList();
    });

final drilldownIncomesProvider = FutureProvider.autoDispose
    .family<List<Income>, String>((ref, key) async {
      final parts = key.split('|');
      final startDate = parts[0];
      final endDate = parts[1];
      final categoryId = parts.length > 2 && parts[2].isNotEmpty
          ? parts[2]
          : null;
      final search = parts.length > 3 ? parts[3] : '';

      final repository = ref.watch(transactionRepositoryProvider);
      final result = await repository.getIncomes(
        page: 1,
        limit: 500,
        search: search,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
      );
      return (result['data'] as List).map((e) => Income.fromJson(e)).toList();
    });
