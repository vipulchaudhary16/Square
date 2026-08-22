import 'package:dio/dio.dart';
import 'feature_flag_model.dart';

class FeatureFlagsRepository {
  final Dio _dio;

  FeatureFlagsRepository(this._dio);

  Future<List<FeatureFlag>> getFlags() async {
    final response = await _dio.get('/users/me/flags');
    return (response.data as List)
        .map((e) => FeatureFlag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FeatureFlag>> updateFlag(String id, bool value) async {
    final response = await _dio.patch('/users/me/flags', data: {id: value});
    return (response.data as List)
        .map((e) => FeatureFlag.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
