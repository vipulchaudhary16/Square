import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../transactions/data/loan_model.dart';
import '../../data/loans_repository.dart';

class ReminderSheet extends StatefulWidget {
  final Loan loan;
  final String token;
  final LoansRepository repository;

  const ReminderSheet({
    super.key,
    required this.loan,
    required this.token,
    required this.repository,
  });

  static void show(
    BuildContext context, {
    required Loan loan,
    required String token,
    required LoansRepository repository,
  }) {
    AppBottomSheet.show(
      context,
      title: 'Set Reminder',
      builder: (_) => ReminderSheet(loan: loan, token: token, repository: repository),
    );
  }

  @override
  State<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<ReminderSheet> {
  DateTime? _selectedDate;
  bool _nudgeBorrower = false;
  bool _loading = false;
  String? _error;

  void _selectQuickDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      setState(() => _error = 'Select a date');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repository.setReminder(
        widget.token,
        widget.loan.id,
        remindAt: _selectedDate!,
        nudgeBorrower: _nudgeBorrower,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder set')),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final hasDueDate = widget.loan.dueDate != null;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final inThreeDays = DateTime.now().add(const Duration(days: 3));
    final isCustom = _selectedDate != null &&
        !_isSameDay(_selectedDate!, tomorrow) &&
        !_isSameDay(_selectedDate!, inThreeDays) &&
        !(hasDueDate && _isSameDay(_selectedDate!, widget.loan.dueDate!));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(
                label: 'Tomorrow',
                selected: _selectedDate != null && _isSameDay(_selectedDate!, tomorrow),
                onTap: () => _selectQuickDate(tomorrow),
              ),
              AppChip(
                label: 'In 3 days',
                selected: _selectedDate != null && _isSameDay(_selectedDate!, inThreeDays),
                onTap: () => _selectQuickDate(inThreeDays),
              ),
              AppChip(
                label: 'On due date',
                selected: hasDueDate && _selectedDate != null && _isSameDay(_selectedDate!, widget.loan.dueDate!),
                onTap: hasDueDate ? () => _selectQuickDate(widget.loan.dueDate!) : null,
              ),
              AppChip(
                label: 'Custom',
                icon: Icons.calendar_month_outlined,
                selected: isCustom,
                onTap: _pickCustomDate,
              ),
            ],
          ),
          if (_selectedDate != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Reminder: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: AppTypography.bodyMuted.copyWith(color: inkFaint),
            ),
          ],
          if (widget.loan.direction == 'lent' && widget.loan.borrowerUserId != null) ...[
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Also nudge ${widget.loan.contactName}', style: AppTypography.bodyMuted.copyWith(color: ink)),
              value: _nudgeBorrower,
              onChanged: (v) => setState(() => _nudgeBorrower = v),
              dense: true,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: AppTypography.errorText.copyWith(color: AppColors.negative)),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(text: 'Set Reminder', onPressed: _submit, isLoading: _loading),
        ],
      ),
    );
  }
}
