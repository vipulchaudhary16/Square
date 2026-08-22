import 'package:dio/dio.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Login failed: ${e.message}';
    }
  }

  Future<Map<String, dynamic>> signup(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Signup failed';
    }
  }

  /// Best-effort — the caller always clears local session state regardless
  /// of whether this succeeds.
  Future<void> logout(String refreshToken) async {
    await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
  }
}
