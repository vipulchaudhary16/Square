import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';

class TransactionRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<Map<String, dynamic>> getExpenses(
    String token, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/expenses',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List<dynamic> data =
          response.data['data'] ?? []; // Adjust based on API response structure
      final int total = response.data['total'] ?? 0;
      return {'data': data, 'total': total};
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  Future<Map<String, dynamic>> getIncomes(
    String token, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/incomes',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List<dynamic> data = response.data['data'] ?? [];
      final int total = response.data['total'] ?? 0;
      return {'data': data, 'total': total};
    } catch (e) {
      throw Exception('Failed to fetch incomes: $e');
    }
  }

  Future<Map<String, dynamic>> getInvestments(
    String token, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/investments',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List<dynamic> data = response.data['data'] ?? [];
      final int total = response.data['total'] ?? 0;
      return {'data': data, 'total': total};
    } catch (e) {
      throw Exception('Failed to fetch investments: $e');
    }
  }

  Future<Map<String, dynamic>> getLoans(
    String token, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/loans',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final List<dynamic> data = response.data['data'] ?? [];
      final int total = response.data['total'] ?? 0;
      return {'data': data, 'total': total};
    } catch (e) {
      throw Exception('Failed to fetch loans: $e');
    }
  }

  // Create Methods
  Future<void> createExpense(String token, Map<String, dynamic> data) async {
    try {
      await _dio.post(
        '/expenses',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  Future<void> createIncome(String token, Map<String, dynamic> data) async {
    try {
      await _dio.post(
        '/incomes',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to create income: $e');
    }
  }

  Future<void> createInvestment(String token, Map<String, dynamic> data) async {
    try {
      await _dio.post(
        '/investments',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to create investment: $e');
    }
  }

  Future<void> createLoan(String token, Map<String, dynamic> data) async {
    try {
      await _dio.post(
        '/loans',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Failed to create loan: $e');
    }
  }
}
