import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/group_model.dart';

/// A settlement is a completed payment, not a shared expense — it renders as
/// a centered system-log line (divider · icon · text) rather than a card, so
/// it reads at a glance as "this happened" instead of "tap for details".
class SettlementLogRow extends StatelessWidget {
  const SettlementLogRow({super.key, required this.settlement, required this.currentUserId});

  final Settlement settlement;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final line = isDark ? AppColors.lineDark : AppColors.line;

    final String title;
    if (settlement.fromUserId == currentUserId) {
      title = 'You paid ${settlement.toUserName}';
    } else if (settlement.toUserId == currentUserId) {
      title = '${settlement.fromUserName} paid you';
    } else {
      title = '${settlement.fromUserName} paid ${settlement.toUserName}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Divider(color: line, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync_alt, size: 13, color: inkFaint),
                const SizedBox(width: 4),
                Text(title, style: AppTypography.caption.copyWith(color: inkFaint)),
                const SizedBox(width: 4),
                Text(
                  formatInr(settlement.amount),
                  style: AppTypography.caption.copyWith(color: ink, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Text('·', style: AppTypography.caption.copyWith(color: inkFaint)),
                const SizedBox(width: 4),
                Text(DateFormat('MMM d').format(settlement.date), style: AppTypography.caption.copyWith(color: inkFaint)),
              ],
            ),
          ),
          Expanded(child: Divider(color: line, height: 1)),
        ],
      ),
    );
  }
}
