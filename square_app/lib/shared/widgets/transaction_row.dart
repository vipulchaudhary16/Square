import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_card.dart';

/// The single row layout used everywhere a transaction/expense/income/loan
/// entry is listed: leading icon tile, title + meta line, trailing content.
/// Callers own the trailing widget so involvement math (expenses) and
/// type-specific formatting (transactions feed) stay in their own files —
/// only the outer chrome is shared.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.metaParts,
    required this.trailing,
    this.accentColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final List<String> metaParts;
  final Widget trailing;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final accent = accentColor ?? ink;

    return AppInteractiveCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardHeading.copyWith(color: ink),
                ),
                if (metaParts.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    metaParts.join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMuted.copyWith(color: inkFaint),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ),
    );
  }
}

/// Common trailing shape: a primary line (usually [AmountText]) with an
/// optional smaller label beneath it.
class TransactionTrailing extends StatelessWidget {
  const TransactionTrailing({super.key, required this.primary, this.secondary});

  final Widget primary;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        primary,
        if (secondary != null) ...[
          const SizedBox(height: 2),
          Text(secondary!, style: AppTypography.caption.copyWith(color: inkFaint)),
        ],
      ],
    );
  }
}
