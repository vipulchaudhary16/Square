import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// One option in a two-way segmented toggle — a label that fills its slot
/// with a solid background when selected. Compose two inside a
/// sunken-background Row to build the full control (see
/// AnalysisReportView) — kept as a single-option widget since that's how
/// the original Spending/Income toggle was already structured.
class SegmentedToggleOption extends StatelessWidget {
  const SegmentedToggleOption({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: selected ? Border.all(color: isDark ? AppColors.lineDark : AppColors.line) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.bodyMuted.copyWith(
              color: selected ? ink : inkFaint,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
