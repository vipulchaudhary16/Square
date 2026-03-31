import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import 'user_model.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

class UserRepository {
  final Dio _dio;

  UserRepository({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<List<User>> searchUsers(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.get(
        '/users/search',
        queryParameters: {'q': query},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final List<dynamic> data = response.data is List
          ? response.data
          : response.data['data'] ?? [];
      
      return data.map((json) => User.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Search failed';
    }
  }
}
