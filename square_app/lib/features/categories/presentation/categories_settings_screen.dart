import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_icon_button.dart';
import '../../../shared/widgets/buttons/button_shell.dart';
import '../../../shared/widgets/ghost_button.dart';
import '../../../shared/widgets/input_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/category_model.dart';
import 'categories_provider.dart';

const _typeLabels = {
  'expense': 'Expense',
  'income': 'Income',
  'budget': 'Budget',
};

class CategoriesSettingsScreen extends ConsumerStatefulWidget {
  const CategoriesSettingsScreen({super.key});

  @override
  ConsumerState<CategoriesSettingsScreen> createState() =>
      _CategoriesSettingsScreenState();
}

class _CategoriesSettingsScreenState
    extends ConsumerState<CategoriesSettingsScreen> {
  Future<void> _openCreateDialog() async {
    await AppDialog.showCustom(
      context,
      builder: (dialogContext) => _CategoryFormDialogContent(
        title: 'New category',
        submitLabel: 'Create',
        initialName: '',
        initialTypes: const ['expense', 'income', 'budget'],
        initialColorHex: null,
        onSubmit: (name, types, color) async {
          await ref.read(categoriesProvider.notifier).create(name, types, color: color);
        },
      ),
    );
  }

  Future<void> _openEditDialog(Category cat) async {
    await AppDialog.showCustom(
      context,
      builder: (dialogContext) => _CategoryFormDialogContent(
        title: 'Edit category',
        submitLabel: 'Save',
        initialName: cat.name,
        initialTypes: cat.appliesTo,
        initialColorHex: cat.color,
        onSubmit: (name, types, color) async {
          await ref.read(categoriesProvider.notifier).updateCategory(cat.id, name, types, color: color);
        },
      ),
    );
  }

  Future<void> _delete(Category cat) async {
    final confirmed = await AppDialog.show<bool>(
      context,
      title: 'Delete category',
      message: 'Deleting "${cat.name}" will move all its records to "Other". Continue?',
      actions: [
        AppDialogAction(label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
        AppDialogAction(
          label: 'Delete',
          isDestructive: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (confirmed != true) return;
    try {
      await ref.read(categoriesProvider.notifier).delete(cat.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negative),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;

    return Scaffold(
      appBar: AppBar(
        title: Text('Categories', style: AppTypography.screenTitle.copyWith(color: ink)),
        actions: [
          AppIconButton(icon: Icons.add, onPressed: _openCreateDialog),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e', style: AppTypography.body.copyWith(color: ink))),
        data: (categories) => GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisExtent: 164,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) => _buildCategoryTile(categories[index]),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(Category cat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final accent = AppColors.resolveCategoryColor(cat.name, colorHex: cat.color);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
              if (cat.isStandard)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Icon(Icons.lock_outline, size: 14, color: inkFaint),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIconButton(
                      icon: Icons.edit,
                      size: 26,
                      iconSize: 13,
                      onPressed: () => _openEditDialog(cat),
                    ),
                    const SizedBox(width: 4),
                    AppIconButton(
                      icon: Icons.delete_outline,
                      size: 26,
                      iconSize: 13,
                      onPressed: () => _delete(cat),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            cat.name,
            style: AppTypography.cardHeading.copyWith(color: ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: cat.appliesTo.map((type) => AppChip(label: _typeLabels[type] ?? type)).toList(),
          ),
        ],
      ),
    );
  }
}

/// Shared body for both the create and edit category dialogs: name field +
/// scope chips + submit/cancel. Owns its own controller/selection state so
/// it can live inside a [Dialog] independently of the parent screen.
class _CategoryFormDialogContent extends StatefulWidget {
  const _CategoryFormDialogContent({
    required this.title,
    required this.submitLabel,
    required this.initialName,
    required this.initialTypes,
    required this.initialColorHex,
    required this.onSubmit,
  });

  final String title;
  final String submitLabel;
  final String initialName;
  final List<String> initialTypes;
  final String? initialColorHex;
  final Future<void> Function(String name, List<String> types, String? colorHex) onSubmit;

  @override
  State<_CategoryFormDialogContent> createState() => _CategoryFormDialogContentState();
}

class _CategoryFormDialogContentState extends State<_CategoryFormDialogContent> {
  late final _nameController = TextEditingController(text: widget.initialName);
  late final List<String> _selectedTypes = [...widget.initialTypes];
  late Color _selectedColor = AppColors.parseHex(widget.initialColorHex) ?? AppColors.categoryAccents.first;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        if (_selectedTypes.length > 1) _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(name, _selectedTypes, AppColors.toHex(_selectedColor));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: AppTypography.cardHeading.copyWith(color: ink)),
        const SizedBox(height: AppSpacing.lg),
        InputField(label: 'Name', hint: 'e.g. Groceries', controller: _nameController),
        const SizedBox(height: AppSpacing.md),
        Text('APPLIES TO', style: AppTypography.label.copyWith(color: inkFaint)),
        const SizedBox(height: AppSpacing.sm),
        Column(
          children: _typeLabels.entries.map((entry) {
            final selected = _selectedTypes.contains(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _ScopeCheckboxOption(
                label: entry.value,
                selected: selected,
                onTap: () => _toggleType(entry.key),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('COLOR', style: AppTypography.label.copyWith(color: inkFaint)),
        const SizedBox(height: AppSpacing.sm),
        _CategoryColorPicker(
          selectedColor: _selectedColor,
          onChanged: (color) => setState(() => _selectedColor = color),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: AppTypography.errorText.copyWith(color: AppColors.negative)),
        ],
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GhostButton(
              text: 'Cancel',
              compact: true,
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.sm),
            PrimaryButton(
              text: widget.submitLabel,
              fullWidth: false,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ],
    );
  }
}

/// Checkbox-style row for the scope selector — a multi-select checklist
/// reads clearer here than pill chips, since these are boolean flags rather
/// than a single filter choice.
class _ScopeCheckboxOption extends StatelessWidget {
  const _ScopeCheckboxOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final onSelectedFg = isDark ? AppColors.surfaceSunkenDark : AppColors.surface;

    return ButtonShell(
      onTap: onTap,
      borderRadius: AppRadius.md,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? sunken : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? ink : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: selected ? ink : line, width: 1.4),
              ),
              child: selected ? Icon(Icons.check, size: 14, color: onSelectedFg) : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: ink,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Predefined swatches (the app's existing categoryAccents palette) plus a
/// custom option opening a full color picker for anything outside that set.
class _CategoryColorPicker extends StatelessWidget {
  const _CategoryColorPicker({required this.selectedColor, required this.onChanged});

  final Color selectedColor;
  final ValueChanged<Color> onChanged;

  bool get _isCustom => !AppColors.categoryAccents.any((c) => c == selectedColor);

  Future<void> _openCustomPicker(BuildContext context) async {
    Color picked = selectedColor;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (c) => picked = c,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Select'),
          ),
        ],
      ),
    );
    if (confirmed == true) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final isCustom = _isCustom;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ...AppColors.categoryAccents.map((color) {
          final selected = !isCustom && color == selectedColor;
          return GestureDetector(
            onTap: () => onChanged(color),
            child: _ColorSwatch(color: color, selected: selected, ink: ink),
          );
        }),
        GestureDetector(
          onTap: () => _openCustomPicker(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCustom ? selectedColor : null,
              gradient: isCustom
                  ? null
                  : const SweepGradient(colors: [
                      Color(0xFFE94E4E),
                      Color(0xFFE9C64E),
                      Color(0xFF4EE96B),
                      Color(0xFF4EA9E9),
                      Color(0xFF9E4EE9),
                      Color(0xFFE94E4E),
                    ]),
              border: isCustom ? Border.all(color: ink, width: 2.5) : null,
            ),
            child: Icon(
              isCustom ? Icons.check : Icons.colorize,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color, required this.selected, required this.ink});

  final Color color;
  final bool selected;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: selected ? Border.all(color: ink, width: 2.5) : null,
      ),
      child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
    );
  }
}
