import 'package:dio/dio.dart';
import 'expense_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final expenseRepositoryProvider = Provider(
  (ref) => ExpenseRepository(ref.watch(apiClientProvider)),
);

class ExpenseRepository {
  final Dio _dio;

  ExpenseRepository(this._dio);

  Future<List<Expense>> getExpenses() async {
    try {
      final response = await _dio.get('/expenses');
      final List<dynamic> data = response.data;
      return data.map((json) => Expense.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch expenses';
    }
  }

  Future<Expense> getExpenseById(String id) async {
    try {
      final response = await _dio.get('/expenses/$id');
      // GET /expenses/:id wraps the expense fields under an "expense" key
      // (alongside logs/comments/users), unlike the flat array from index.
      return Expense.fromJson(response.data['expense']);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch expense details';
    }
  }

  Future<void> createExpense(Map<String, dynamic> expenseData) async {
    try {
      await _dio.post('/expenses', data: expenseData);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to create expense';
    }
  }

  Future<void> updateExpense(
    String id,
    Map<String, dynamic> expenseData,
  ) async {
    try {
      await _dio.put('/expenses/$id', data: expenseData);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to update expense';
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _dio.delete('/expenses/$id');
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to delete expense';
    }
  }
}
