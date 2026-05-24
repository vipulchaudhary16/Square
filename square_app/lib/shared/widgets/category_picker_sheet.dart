import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/categories/presentation/categories_provider.dart';

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

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
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
    final bg = isDark ? AppColors.slate[900]! : Colors.white;

    final allCats = catsAsync.value
            ?.where((c) => c.appliesTo.contains(widget.appliesTo))
            .toList() ??
        [];
    final filtered = _query.isEmpty
        ? allCats
        : allCats
            .where(
                (c) => c.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Select Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.slate[900],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.slate[300]!),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: catsAsync.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : catsAsync.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Failed to load categories',
                          style: TextStyle(color: AppColors.slate[500]),
                        ),
                      )
                    : filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _query.isEmpty
                                  ? 'No categories available'
                                  : 'No results for "$_query"',
                              style: TextStyle(color: AppColors.slate[500]),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final cat = filtered[i];
                              final selected = widget.selectedId == cat.id;
                              return ListTile(
                                title: Text(cat.name),
                                trailing: selected
                                    ? Icon(
                                        Icons.check,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      )
                                    : null,
                                selected: selected,
                                onTap: () {
                                  widget.onSelected(cat.id, cat.name);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
          ),
          SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom + 8),
        ],
      ),
    );
  }
}
