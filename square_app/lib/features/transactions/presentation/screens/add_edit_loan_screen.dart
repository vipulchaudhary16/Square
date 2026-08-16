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
import '../../../contacts/data/contact_model.dart';
import '../../../transactions/data/loan_model.dart';
import '../transactions_provider.dart';

class AddEditLoanScreen extends ConsumerStatefulWidget {
  final Loan? loan;
  const AddEditLoanScreen({super.key, this.loan});

  @override
  ConsumerState<AddEditLoanScreen> createState() => _AddEditLoanScreenState();
}

class _AddEditLoanScreenState extends ConsumerState<AddEditLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Contact? _selectedContact;
  String _interestMode = 'none';
  final _interestRateController = TextEditingController();
  String _interestPeriod = 'annual';
  String _interestBasis = 'principal';
  DateTime _selectedDate = DateTime.now();
  DateTime? _dueDate;
  bool _isLoading = false;
  String? _selectedCategoryId;
  String _selectedCategoryName = 'Category';

  bool get _isEditing => widget.loan != null;

  @override
  void initState() {
    super.initState();
    final loan = widget.loan;
    if (loan != null) {
      _amountController.text = loan.amount.toString();
      _descriptionController.text = loan.description ?? '';
      _interestMode = loan.interestMode;
      _interestPeriod = loan.interestPeriod ?? 'annual';
      _interestBasis = loan.interestBasis ?? 'principal';
      if (loan.interestRate != null) {
        _interestRateController.text = loan.interestRate!.toString();
      }
      _selectedDate = loan.date;
      _dueDate = loan.dueDate;
      _selectedCategoryId = loan.categoryId.isNotEmpty ? loan.categoryId : null;
      _selectedCategoryName = loan.categoryName.isNotEmpty ? loan.categoryName : 'Category';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    final result = await context.push<Contact>('/contacts/add');
    if (result != null) setState(() => _selectedContact = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _selectedContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a contact')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = {
        if (!_isEditing) 'contact_id': _selectedContact!.id,
        'amount': double.parse(_amountController.text.replaceAll(',', '')),
        'date': _selectedDate.toUtc().toIso8601String(),
        'interest_mode': _interestMode,
        'description': _descriptionController.text,
        'category_id': _selectedCategoryId ?? '',
        if (_dueDate != null) 'due_date': _dueDate!.toUtc().toIso8601String(),
        if (_interestMode != 'none' && _interestRateController.text.isNotEmpty)
          'interest_rate': double.parse(_interestRateController.text),
        if (_interestMode != 'none') 'interest_period': _interestPeriod,
        if (_interestMode != 'none') 'interest_basis': _interestBasis,
      };
      if (_isEditing) {
        await ref.read(loansProvider.notifier).updateLoan(widget.loan!.id, data);
      } else {
        await ref.read(loansProvider.notifier).create(data);
      }
      if (mounted) {
        context.pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Loan updated' : 'Loan added')),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final line = isDark ? AppColors.lineDark : AppColors.line;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceSunkenDark : AppColors.surface,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Loan' : 'Add Loan',
            style: AppTypography.screenTitle.copyWith(color: ink, fontSize: 18)),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                if (!_isEditing)
                  GestureDetector(
                    onTap: _pickContact,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: sunken,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: line),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 20, color: inkFaint),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              _selectedContact?.name ?? 'Select contact',
                              style: AppTypography.body.copyWith(
                                color: _selectedContact != null ? ink : inkFaint,
                                fontWeight: _selectedContact != null ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: inkFaint),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                AmountInputField(controller: _amountController),
                const SizedBox(height: AppSpacing.xl),
                _buildInterestModeSelector(isDark, ink, inkFaint),
                const SizedBox(height: AppSpacing.lg),
                InputField(
                  label: 'Description',
                  hint: 'Optional note',
                  controller: _descriptionController,
                  prefixIcon: Icons.description_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 180),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: _buildFloatingDock(isDark),
    );
  }

  Widget _buildRadioRow<T>({
    required List<(T, String)> options,
    required T selected,
    required ValueChanged<T> onChanged,
    required Color ink,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.indexed.map((entry) {
        final i = entry.$1;
        final opt = entry.$2;
        final isSelected = opt.$1 == selected;
        return Padding(
          padding: EdgeInsets.only(right: i < options.length - 1 ? AppSpacing.lg : 0),
          child: GestureDetector(
            onTap: () => onChanged(opt.$1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: isSelected ? ink : ink.withValues(alpha: 0.3),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  opt.$2,
                  style: AppTypography.bodyMuted.copyWith(
                    color: ink,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInterestModeSelector(bool isDark, Color ink, Color inkFaint) {
    final modes = [
      ('none', 'None'),
      ('from_start', 'From start'),
      ('penalty', 'Penalty'),
    ];
    final periods = [
      ('daily', 'Daily'),
      ('monthly', 'Monthly'),
      ('annual', 'Annual'),
    ];
    final bases = [
      ('principal', 'Simple'),
      ('total', 'Compound'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INTEREST TYPE', style: AppTypography.label.copyWith(color: inkFaint)),
        const SizedBox(height: AppSpacing.sm),
        _buildRadioRow(options: modes, selected: _interestMode, onChanged: (v) => setState(() => _interestMode = v), ink: ink),
        if (_interestMode != 'none') ...[
          const SizedBox(height: AppSpacing.lg),
          InputField(
            label: 'Rate %',
            hint: 'e.g. 12',
            controller: _interestRateController,
            prefixIcon: Icons.percent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (_interestMode == 'none') return null;
              if (v == null || v.isEmpty) return 'Required';
              if (double.tryParse(v) == null) return 'Invalid number';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text('PERIOD', style: AppTypography.label.copyWith(color: inkFaint)),
          const SizedBox(height: AppSpacing.sm),
          _buildRadioRow(options: periods, selected: _interestPeriod, onChanged: (v) => setState(() => _interestPeriod = v), ink: ink),
          const SizedBox(height: AppSpacing.md),
          Text('CALCULATION', style: AppTypography.label.copyWith(color: inkFaint)),
          const SizedBox(height: AppSpacing.sm),
          _buildRadioRow(options: bases, selected: _interestBasis, onChanged: (v) => setState(() => _interestBasis = v), ink: ink),
        ],
      ],
    );
  }

  Widget _buildFloatingDock(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceRaisedDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? AppColors.lineDark : AppColors.line),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          _buildDockItem(
            Icons.calendar_month_outlined,
            DateFormat('MMM dd').format(_selectedDate),
            isDark,
            () async {
              final picked = await showDatePicker(
                  context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          _buildDockItem(
            Icons.calendar_month_outlined,
            _dueDate != null ? 'Due ${DateFormat('MMM dd').format(_dueDate!)}' : 'Due date',
            isDark,
            () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
          ),
          _buildDockItem(
            Icons.label_outline,
            _selectedCategoryName,
            isDark,
            () => CategoryPickerSheet.show(
              context,
              selectedId: _selectedCategoryId,
              appliesTo: 'loan',
              onSelected: (id, name) => setState(() {
                _selectedCategoryId = id;
                _selectedCategoryName = name;
              }),
            ),
          ),
        ],
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
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyEmphasis.copyWith(color: ink, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
