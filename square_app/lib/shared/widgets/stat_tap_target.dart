import 'package:flutter/material.dart';
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
  });

  final String label;
  final Color color;
  final double amount;
  final bool alignEnd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}
