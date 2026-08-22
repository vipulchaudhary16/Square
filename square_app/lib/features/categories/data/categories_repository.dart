import 'package:dio/dio.dart';
import 'category_model.dart';

class CategoriesRepository {
  final Dio _dio;

  CategoriesRepository(this._dio);

  Future<List<Category>> getCategories({String? appliesTo}) async {
    final queryParams = appliesTo != null ? {'applies_to': appliesTo} : null;
    final response = await _dio.get(
      '/categories',
      queryParameters: queryParams,
    );
    return (response.data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> createCategory(
    String name,
    List<String> appliesTo, {
    String? color,
  }) async {
    final response = await _dio.post(
      '/categories',
      data: {
        'name': name,
        'applies_to': appliesTo,
        if (color != null) 'color': color,
      },
    );
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Category> updateCategory(
    String id,
    String name,
    List<String> appliesTo, {
    String? color,
  }) async {
    final response = await _dio.patch(
      '/categories/$id',
      data: {
        'name': name,
        'applies_to': appliesTo,
        if (color != null) 'color': color,
      },
    );
    return Category.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete('/categories/$id');
  }
}
