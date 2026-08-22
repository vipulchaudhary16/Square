import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/categories/presentation/categories_provider.dart';
import 'app_bottom_sheet.dart';
import 'app_empty_state.dart';
import 'app_error_state.dart';
import 'buttons/button_shell.dart';

class CategoryPickerSheet extends ConsumerStatefulWidget {
  final String? selectedId;
  final String appliesTo;
  final void Function(String id, String name) onSelected;

  const CategoryPickerSheet({
    super.key,
    required this.selectedId,
    required this.appliesTo,
    required this.onSelected,
  });

  /// Convenience opener wired to [AppBottomSheet] so callers don't need to
  /// reach for `showModalBottomSheet` directly.
  static Future<void> show(
    BuildContext context, {
    required String? selectedId,
    required String appliesTo,
    required void Function(String id, String name) onSelected,
  }) {
    return AppBottomSheet.show(
      context,
      title: 'Select Category',
      builder: (context) => CategoryPickerSheet(
        selectedId: selectedId,
        appliesTo: appliesTo,
        onSelected: onSelected,
      ),
    );
  }

  @override
  ConsumerState<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;

    final allCats = catsAsync.value?.where((c) => c.appliesTo.contains(widget.appliesTo)).toList() ?? [];
    final filtered = _query.isEmpty
        ? allCats
        : allCats.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: sunken,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: line),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTypography.body.copyWith(color: ink),
                decoration: InputDecoration(
                  hintText: 'Search categories…',
                  hintStyle: AppTypography.body.copyWith(color: inkFaint),
                  prefixIcon: Icon(Icons.search, size: 18, color: inkFaint),
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          Expanded(
            child: catsAsync.isLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                : catsAsync.hasError
                    ? AppErrorState(message: 'Failed to load categories')
                    : filtered.isEmpty
                        ? AppEmptyState(
                            icon: Icons.label_outline,
                            title: _query.isEmpty ? 'No categories available' : 'No results',
                            message: _query.isEmpty ? null : 'Nothing matches "$_query"',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final cat = filtered[i];
                              final selected = widget.selectedId == cat.id;
                              final accent = AppColors.resolveCategoryColor(cat.name, colorHex: cat.color);
                              return ButtonShell(
                                onTap: () {
                                  widget.onSelected(cat.id, cat.name);
                                  Navigator.pop(context);
                                },
                                borderRadius: AppRadius.md,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Text(cat.name, style: AppTypography.body.copyWith(color: ink)),
                                      ),
                                      if (selected)
                                        Icon(Icons.check, size: 18, color: ink),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
