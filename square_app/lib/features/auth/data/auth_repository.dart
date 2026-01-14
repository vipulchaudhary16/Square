import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Making request to: ${_dio.options.baseUrl}/auth/login');
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      print('Login Error: ${e.message}');
      print('Login response: ${e.response?.data}');
      throw e.response?.data['error'] ?? 'Login failed: ${e.message}';
    } catch (e) {
      print('Unexpected Login Error: $e');
      throw 'An unexpected error occurred';
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
}
