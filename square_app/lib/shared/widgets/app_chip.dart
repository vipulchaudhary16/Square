import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'buttons/button_shell.dart';

enum AppChipStatus { neutral, positive, negative, warning }

/// Filter/selection chip and status pill, sharing one implementation.
/// Selection state is always monochrome (filled ink/white) — [status] is
/// reserved for semantic meaning like "Settled" / "Pending" / "Overdue".
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.status,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final AppChipStatus? status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (status != null && status != AppChipStatus.neutral) {
      final (fg, bg) = switch (status!) {
        AppChipStatus.positive => (
            AppColors.positive,
            isDark ? AppColors.positiveSoftDark : AppColors.positiveSoft,
          ),
        AppChipStatus.negative => (
            AppColors.negative,
            isDark ? AppColors.negativeSoftDark : AppColors.negativeSoft,
          ),
        AppChipStatus.warning => (
            AppColors.warning,
            isDark ? AppColors.warningSoftDark : AppColors.warningSoft,
          ),
        AppChipStatus.neutral => (AppColors.ink, AppColors.surfaceSunken),
      };
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Text(label, style: AppTypography.label.copyWith(color: fg, letterSpacing: 0.2)),
      );
    }

    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkMuted = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    // Unselected gets a visible sunken fill — in dark mode a transparent chip
    // with only a faint border was nearly indistinguishable from selected.
    final unselectedBg = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final onSelectedFg = isDark ? AppColors.surfaceSunkenDark : AppColors.surface;

    return ButtonShell(
      onTap: onTap,
      borderRadius: 999,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? ink : unselectedBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? ink : line, width: selected ? 1 : 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? onSelectedFg : inkMuted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.bodyMuted.copyWith(
                color: selected ? onSelectedFg : inkMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
