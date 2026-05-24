import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/category_model.dart';
import '../data/categories_repository.dart';

final categoriesRepositoryProvider =
    Provider((_) => CategoriesRepository());

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return ref.read(categoriesRepositoryProvider).getCategories(token);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      return ref.read(categoriesRepositoryProvider).getCategories(token);
    });
  }

  Future<void> create(String name, List<String> appliesTo) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await ref.read(categoriesRepositoryProvider).createCategory(token, name, appliesTo);
    await refresh();
  }

  Future<void> update(String id, String name, List<String> appliesTo) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await ref.read(categoriesRepositoryProvider).updateCategory(token, id, name, appliesTo);
    await refresh();
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await ref.read(categoriesRepositoryProvider).deleteCategory(token, id);
    await refresh();
  }

  List<Category> forType(String type) {
    final cats = state.value;
    if (cats == null) return [];
    return cats.where((c) => c.appliesTo.contains(type)).toList();
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);
