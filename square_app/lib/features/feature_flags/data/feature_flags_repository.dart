import 'package:dio/dio.dart';
import 'package:square_app/core/constants/api_constants.dart';
import 'feature_flag_model.dart';

class FeatureFlagsRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<List<FeatureFlag>> getFlags(String token) async {
    final response = await _dio.get(
      '/users/me/flags',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List)
        .map((e) => FeatureFlag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FeatureFlag>> updateFlag(String token, String id, bool value) async {
    final response = await _dio.patch(
      '/users/me/flags',
      data: {id: value},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List)
        .map((e) => FeatureFlag.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
