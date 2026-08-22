import 'package:dio/dio.dart';

class TransactionRepository {
  final Dio _dio;

  TransactionRepository(this._dio);

  Future<Map<String, dynamic>> getExpenses({
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
    String? startDate,
    String? endDate,
    String? groupId,
  }) async {
    try {
      final response = await _dio.get(
        '/expenses',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (groupId == null) 'personal_only': 'true',
          if (groupId != null) 'group_id': groupId,
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'category_id': categoryId,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );
      final List<dynamic> data =
          response.data['data'] ?? []; // Adjust based on API response structure
      final int total = response.data['total'] ?? 0;
      return {'data': data, 'total': total};
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  Future<Map<String, dynamic>> getIncomes({
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/incomes',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'category_id': categoryId,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );
      final List<dynamic> data = response.data['data'] ?? [];
      final int total = response.data['total'] ?? 0;
      return {'data': data, 'total': total};
    } catch (e) {
      throw Exception('Failed to fetch incomes: $e');
    }
  }

  Future<Map<String, dynamic>> getAnalysis({
    required String startDate,
    required String endDate,
    String? compareStartDate,
    String? compareEndDate,
  }) async {
    try {
      final response = await _dio.get(
        '/analysis',
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
          if (compareStartDate != null) 'compare_start_date': compareStartDate,
          if (compareEndDate != null) 'compare_end_date': compareEndDate,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch analysis: $e');
    }
  }

  Future<Map<String, dynamic>> getInvestments({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/investments',
        queryParameters: {'page': page, 'limit': limit},
      );
      final List<dynamic> data = response.data ?? [];
      final int total = response.data.length ?? 0;
      return {'data': data, 'total': total};
    } catch (e) {
      throw Exception('Failed to fetch investments: $e');
    }
  }

  Future<Map<String, dynamic>> getLoans({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/loans',
        queryParameters: {'page': page, 'limit': limit},
      );
      final List<dynamic> data = response.data ?? [];
      final int total = response.data.length ?? 0;
      return {'data': data, 'total': total};
    } catch (e) {
      throw Exception('Failed to fetch loans: $e');
    }
  }

  // Create Methods
  Future<void> createExpense(Map<String, dynamic> data) async {
    try {
      await _dio.post('/expenses', data: data);
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  Future<void> createIncome(Map<String, dynamic> data) async {
    try {
      await _dio.post('/incomes', data: data);
    } catch (e) {
      throw Exception('Failed to create income: $e');
    }
  }

  Future<void> createInvestment(Map<String, dynamic> data) async {
    try {
      await _dio.post('/investments', data: data);
    } catch (e) {
      throw Exception('Failed to create investment: $e');
    }
  }

  Future<void> createLoan(Map<String, dynamic> data) async {
    try {
      await _dio.post('/loans', data: data);
    } catch (e) {
      throw Exception('Failed to create loan: $e');
    }
  }

  Future<void> updateLoan(String loanId, Map<String, dynamic> data) async {
    try {
      await _dio.patch('/loans/$loanId', data: data);
    } catch (e) {
      throw Exception('Failed to update loan: $e');
    }
  }
}
