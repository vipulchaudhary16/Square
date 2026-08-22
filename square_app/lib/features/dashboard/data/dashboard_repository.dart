import 'package:dio/dio.dart';
import 'dashboard_model.dart';

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<DashboardData> getDashboardData({bool includeTrends = true}) async {
    try {
      final response = await _dio.get(
        '/dashboard',
        queryParameters: {'include_trends': includeTrends.toString()},
      );
      return DashboardData.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to fetch dashboard data';
    }
  }
}
