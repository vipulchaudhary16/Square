import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Large, fast amount-entry field: big live-typed digits, currency symbol,
/// auto-formatted thousands separators. This is the moment that matters most
/// in an expense tracker, so it gets its own component instead of reusing
/// the generic [InputField].
class AmountInputField extends StatefulWidget {
  const AmountInputField({
    super.key,
    required this.controller,
    this.currencySymbol = '₹',
    this.errorText,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String currencySymbol;
  final String? errorText;
  final bool autofocus;

  @override
  State<AmountInputField> createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<AmountInputField> {
  late final _formatter = _ThousandsSeparatorFormatter();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
          child: Text('AMOUNT', style: AppTypography.label.copyWith(color: inkFaint)),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                widget.currencySymbol,
                style: AppTypography.displayAmount.copyWith(color: inkFaint),
              ),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                autofocus: widget.autofocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  _formatter,
                ],
                cursorColor: ink,
                style: AppTypography.displayAmount.copyWith(color: ink),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: AppTypography.displayAmount.copyWith(color: inkFaint.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 120),
          child: hasError
              ? Padding(
                  key: const ValueKey('error'),
                  padding: const EdgeInsets.only(left: 2, top: AppSpacing.sm),
                  child: Text(widget.errorText!, style: AppTypography.errorText.copyWith(color: AppColors.negative)),
                )
              : const SizedBox.shrink(key: ValueKey('none')),
        ),
      ],
    );
  }
}

/// Formats digits with comma thousands separators as the user types, while
/// keeping the cursor at the end (amount entry is always append-only in
/// practice) and preserving a single decimal point.
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final parts = newValue.text.split('.');
    final intDigits = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < intDigits.length; i++) {
      if (i > 0 && (intDigits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intDigits[i]);
    }
    var formatted = buffer.toString();
    if (parts.length > 1) {
      formatted = '$formatted.${parts[1]}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
