import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import 'dashboard_model.dart';

class DashboardRepository {
  final Dio _dio;

  DashboardRepository({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<DashboardData> getDashboardData(String token) async {
    try {
      final response = await _dio.get(
        '/dashboard',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return DashboardData.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch dashboard data';
    }
  }
}
