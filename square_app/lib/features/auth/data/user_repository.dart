import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'user_model.dart';

final userRepositoryProvider = Provider(
  (ref) => UserRepository(ref.watch(apiClientProvider)),
);

class UserRepository {
  final Dio _dio;

  UserRepository(this._dio);

  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '/users/search',
        queryParameters: {'q': query},
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
