import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import 'expense_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final expenseRepositoryProvider = Provider((ref) => ExpenseRepository());

class ExpenseRepository {
  final Dio _dio;

  ExpenseRepository({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<List<Expense>> getExpenses(String token) async {
    try {
      final response = await _dio.get(
        '/expenses',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Expense.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch expenses';
    }
  }

  Future<Expense> getExpenseById(String token, String id) async {
    try {
      final response = await _dio.get(
        '/expenses/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return Expense.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch expense details';
    }
  }

  Future<void> createExpense(
    String token,
    Map<String, dynamic> expenseData,
  ) async {
    try {
      await _dio.post(
        '/expenses',
        data: expenseData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to create expense';
    }
  }

  Future<void> updateExpense(
    String token,
    String id,
    Map<String, dynamic> expenseData,
  ) async {
    try {
      await _dio.put(
        '/expenses/$id',
        data: expenseData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to update expense';
    }
  }

  Future<void> deleteExpense(String token, String id) async {
    try {
      await _dio.delete(
        '/expenses/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to delete expense';
    }
  }
}
