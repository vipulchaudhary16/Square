import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/category_model.dart';
import '../data/categories_repository.dart';

final categoriesRepositoryProvider = Provider(
  (ref) => CategoriesRepository(ref.watch(apiClientProvider)),
);

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return ref.read(categoriesRepositoryProvider).getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(categoriesRepositoryProvider).getCategories();
    });
  }

  Future<void> create(
    String name,
    List<String> appliesTo, {
    String? color,
  }) async {
    await ref
        .read(categoriesRepositoryProvider)
        .createCategory(name, appliesTo, color: color);
    await refresh();
  }

  Future<void> updateCategory(
    String id,
    String name,
    List<String> appliesTo, {
    String? color,
  }) async {
    await ref
        .read(categoriesRepositoryProvider)
        .updateCategory(id, name, appliesTo, color: color);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(categoriesRepositoryProvider).deleteCategory(id);
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
