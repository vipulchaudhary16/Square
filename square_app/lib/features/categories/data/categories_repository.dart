import 'package:dio/dio.dart';
import 'package:square_app/core/constants/api_constants.dart';
import 'category_model.dart';

class CategoriesRepository {
  final Dio _dio;

  CategoriesRepository({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<List<Category>> getCategories(String token, {String? appliesTo}) async {
    final queryParams = appliesTo != null ? {'applies_to': appliesTo} : null;
    final response = await _dio.get(
      '/categories',
      queryParameters: queryParams,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return (response.data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> createCategory(
      String token, String name, List<String> appliesTo) async {
    final response = await _dio.post(
      '/categories',
      data: {'name': name, 'applies_to': appliesTo},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Category> updateCategory(
      String token, String id, String name, List<String> appliesTo) async {
    final response = await _dio.patch(
      '/categories/$id',
      data: {'name': name, 'applies_to': appliesTo},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String token, String id) async {
    await _dio.delete(
      '/categories/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
