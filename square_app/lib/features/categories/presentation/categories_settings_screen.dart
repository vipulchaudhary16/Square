import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/category_model.dart';
import 'categories_provider.dart';

class CategoriesSettingsScreen extends ConsumerStatefulWidget {
  const CategoriesSettingsScreen({super.key});

  @override
  ConsumerState<CategoriesSettingsScreen> createState() =>
      _CategoriesSettingsScreenState();
}

class _CategoriesSettingsScreenState
    extends ConsumerState<CategoriesSettingsScreen> {
  final _nameController = TextEditingController();
  List<String> _selectedTypes = ['expense', 'income', 'budget'];
  bool _showForm = false;
  String? _editingId;
  final _editNameController = TextEditingController();
  List<String> _editTypes = [];

  static const _typeLabels = {
    'expense': 'Expense',
    'income': 'Income',
    'budget': 'Budget',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _editNameController.dispose();
    super.dispose();
  }

  void _toggleType(List<String> types, String type, void Function(List<String>) setter) {
    setState(() {
      if (types.contains(type)) {
        if (types.length > 1) setter(types.where((t) => t != type).toList());
      } else {
        setter([...types, type]);
      }
    });
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    try {
      await ref.read(categoriesProvider.notifier).create(name, _selectedTypes);
      _nameController.clear();
      setState(() {
        _showForm = false;
        _selectedTypes = ['expense', 'income', 'budget'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _update(String id) async {
    final name = _editNameController.text.trim();
    if (name.isEmpty) return;
    try {
      await ref.read(categoriesProvider.notifier).updateCategory(id, name, _editTypes);
      setState(() => _editingId = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _delete(Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            'Deleting "${cat.name}" will move all its records to "Other". Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(categoriesProvider.notifier).delete(cat.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (categories) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_showForm) _buildCreateForm(isDark),
            ...categories.map((cat) => _buildCategoryTile(cat, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.slate[700]! : AppColors.slate[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Category name',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['expense', 'income', 'budget'].map((type) {
              final selected = _selectedTypes.contains(type);
              return FilterChip(
                label: Text(_typeLabels[type]!),
                selected: selected,
                onSelected: (_) => _toggleType(_selectedTypes, type, (v) => _selectedTypes = v),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _create,
                  child: const Text('Create'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _showForm = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(Category cat, bool isDark) {
    final isEditing = _editingId == cat.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.slate[700]! : AppColors.slate[200]!),
      ),
      child: isEditing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _editNameController,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['expense', 'income', 'budget'].map((type) {
                    final selected = _editTypes.contains(type);
                    return FilterChip(
                      label: Text(_typeLabels[type]!),
                      selected: selected,
                      onSelected: (_) => _toggleType(_editTypes, type, (v) => _editTypes = v),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _update(cat.id),
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() => _editingId = null),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.slate[900],
                            ),
                          ),
                          if (cat.isStandard) ...[
                            const SizedBox(width: 6),
                            Icon(LucideIcons.lock, size: 12, color: AppColors.slate[400]),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: cat.appliesTo.map((type) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.slate[700] : AppColors.slate[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _typeLabels[type] ?? type,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.slate[300] : AppColors.slate[600],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                if (!cat.isStandard) ...[
                  IconButton(
                    icon: Icon(LucideIcons.pencil, size: 16, color: AppColors.slate[400]),
                    onPressed: () {
                      setState(() {
                        _editingId = cat.id;
                        _editNameController.text = cat.name;
                        _editTypes = [...cat.appliesTo];
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                    onPressed: () => _delete(cat),
                  ),
                ],
              ],
            ),
    );
  }
}
