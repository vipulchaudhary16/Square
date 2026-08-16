import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/amount_input_field.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/category_picker_sheet.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../transactions/presentation/transactions_provider.dart';

class AddEditIncomeScreen extends ConsumerStatefulWidget {
  const AddEditIncomeScreen({super.key});

  @override
  ConsumerState<AddEditIncomeScreen> createState() =>
      _AddEditIncomeScreenState();
}

class _AddEditIncomeScreenState extends ConsumerState<AddEditIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _selectedCategoryId;
  String _selectedCategoryName = 'Category';

  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final data = {
        'source': _sourceController.text.trim(),
        'amount': amount,
        'description': _descriptionController.text,
        'date': _selectedDate.toUtc().toIso8601String(),
        'category_id': _selectedCategoryId ?? '',
      };
      await ref.read(incomesProvider.notifier).create(data);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.negative),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showCategoryPicker() {
    CategoryPickerSheet.show(
      context,
      selectedId: _selectedCategoryId,
      appliesTo: 'income',
      onSelected: (id, name) => setState(() {
        _selectedCategoryId = id;
        _selectedCategoryName = name;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceSunkenDark : AppColors.surface,
      appBar: AppBar(
        title: Text('Add Income', style: AppTypography.screenTitle.copyWith(color: ink, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: AppIconButton(icon: Icons.close, onPressed: () => context.pop()),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : GhostButton(text: 'Save', compact: true, onPressed: _submit),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    AmountInputField(controller: _amountController, autofocus: true),
                    const SizedBox(height: AppSpacing.xl),
                    InputField(
                      label: 'Source',
                      hint: 'Salary, Freelance, Gift…',
                      controller: _sourceController,
                      prefixIcon: Icons.account_balance_wallet_outlined,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    InputField(
                      label: 'Description',
                      hint: 'Optional note',
                      controller: _descriptionController,
                      prefixIcon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 180),
                  ],
                ),
              ),
            ),
          ),
          _buildFloatingDock(context, isDark),
        ],
      ),
    );
  }

  Widget _buildFloatingDock(BuildContext context, bool isDark) {
    return Positioned(
      bottom: AppSpacing.sm,
      left: AppSpacing.xl,
      right: AppSpacing.xl,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceRaisedDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            _buildDockItem(Icons.calendar_month_outlined, DateFormat('MMM dd').format(_selectedDate), isDark, _pickDate),
            _buildDockItem(Icons.label_outline, _selectedCategoryName, isDark, _showCategoryPicker),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem(IconData icon, String label, bool isDark, VoidCallback onTap) {
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final sunken = isDark ? AppColors.surfaceDark : AppColors.surfaceSunken;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: BoxDecoration(color: sunken, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: ink),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyEmphasis.copyWith(color: ink, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
