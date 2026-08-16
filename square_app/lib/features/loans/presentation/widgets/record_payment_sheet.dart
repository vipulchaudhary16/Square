import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/amount_input_field.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/input_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../transactions/data/loan_model.dart';
import '../../data/loans_repository.dart';

class RecordPaymentSheet extends StatefulWidget {
  final Loan loan;
  final String token;
  final LoansRepository repository;

  const RecordPaymentSheet({
    super.key,
    required this.loan,
    required this.token,
    required this.repository,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Loan loan,
    required String token,
    required LoansRepository repository,
  }) {
    return AppBottomSheet.show<bool>(
      context,
      title: 'Record Payment',
      builder: (_) => RecordPaymentSheet(loan: loan, token: token, repository: repository),
    );
  }

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  DateTime _paidAt = DateTime.now();
  bool _addInterestToIncome = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.loan.totalDue.toStringAsFixed(2));
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '').trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repository.recordPayment(
        widget.token,
        widget.loan.id,
        amount: amount,
        paidAt: _paidAt,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        addInterestToIncome: _addInterestToIncome,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final hasInterest = widget.loan.accruedInterest > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Outstanding ${formatInr(widget.loan.outstanding)}',
              style: AppTypography.bodyMuted.copyWith(color: inkFaint)),
          const SizedBox(height: AppSpacing.lg),
          AmountInputField(controller: _amountCtrl, errorText: _error),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _paidAt,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _paidAt = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: sunken,
                border: Border.all(color: line),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 16, color: inkFaint),
                  const SizedBox(width: AppSpacing.sm),
                  Text(DateFormat('dd MMM y').format(_paidAt), style: AppTypography.body.copyWith(color: ink)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          InputField(label: 'Note', hint: 'Optional', controller: _noteCtrl),
          if (hasInterest) ...[
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Add ${formatInr(widget.loan.accruedInterest)} interest to Income',
                style: AppTypography.bodyMuted.copyWith(color: ink),
              ),
              value: _addInterestToIncome,
              onChanged: (v) => setState(() => _addInterestToIncome = v),
              dense: true,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(text: 'Confirm Payment', onPressed: _submit, isLoading: _loading),
        ],
      ),
    );
  }
}
