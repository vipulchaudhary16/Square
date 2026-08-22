import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'amount_text.dart';

/// A label + amount that's optionally tappable to drill into that stat's
/// transaction list. Shared between the personal analysis screen
/// (Spending/Income) and the group report (Total expense/Your share).
class StatTapTarget extends StatelessWidget {
  const StatTapTarget({
    super.key,
    required this.label,
    required this.color,
    required this.amount,
    this.onTap,
    this.alignEnd = false,
    this.deltaPercent,
    this.comparisonLabel,
    this.increaseIsGood = false,
  });

  final String label;
  final Color color;
  final double amount;
  final bool alignEnd;
  final VoidCallback? onTap;

  /// Percent change vs [comparisonLabel]'s period. Null (or a null
  /// [comparisonLabel]) renders no delta row at all.
  final double? deltaPercent;

  /// e.g. "last month" — must be non-null for [deltaPercent] to render.
  final String? comparisonLabel;

  /// Whether an increase should read as positive (green) rather than the
  /// default negative (red) — true for income-like tiles, false for
  /// spending-like ones.
  final bool increaseIsGood;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label.copyWith(color: color)),
          const SizedBox(height: 4),
          // AmountText has its own tap gesture (shows an in-words tooltip) that
          // would otherwise compete with this card's tap-to-drill-down — ignore
          // its pointer so tapping the number always opens the list.
          IgnorePointer(
            child: AmountText(
              amount: amount,
              sign: AmountSign.neutral,
              style: AppTypography.amountLarge,
            ),
          ),
          if (deltaPercent != null && comparisonLabel != null) ...[
            const SizedBox(height: 2),
            _DeltaRow(
              percent: deltaPercent!,
              comparisonLabel: comparisonLabel!,
              increaseIsGood: increaseIsGood,
              inkFaint: inkFaint,
            ),
          ],
        ],
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  const _DeltaRow({
    required this.percent,
    required this.comparisonLabel,
    required this.increaseIsGood,
    required this.inkFaint,
  });

  final double percent;
  final String comparisonLabel;
  final bool increaseIsGood;
  final Color inkFaint;

  @override
  Widget build(BuildContext context) {
    // A near-zero delta isn't really "up" or "down" — call it flat rather
    // than picking an arbitrary direction on noise.
    if (percent.abs() < 0.05) {
      return Text('No change vs $comparisonLabel', style: AppTypography.caption.copyWith(color: inkFaint));
    }

    final isIncrease = percent > 0;
    final isGood = isIncrease == increaseIsGood;
    final deltaColor = isGood ? AppColors.positive : AppColors.negative;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 12,
          color: deltaColor,
        ),
        const SizedBox(width: 2),
        Text(
          '${percent.abs().toStringAsFixed(1)}% vs $comparisonLabel',
          style: AppTypography.caption.copyWith(color: deltaColor),
        ),
      ],
    );
  }
}
