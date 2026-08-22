import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/transactions/data/analysis_model.dart';
import '../../features/transactions/presentation/widgets/category_donut_chart.dart';
import 'app_card.dart';
import 'segmented_toggle.dart';
import 'stat_tap_target.dart';

/// A single stat tile fed into [AnalysisReportView] — e.g. Spending/Income
/// for the personal report, Total expense/Your share for a group report.
/// [onTap] is optional: a tile with no [onTap] renders as a static (non-
/// tappable) stat.
class AnalysisStatTile {
  const AnalysisStatTile({
    required this.label,
    required this.color,
    required this.amount,
    this.onTap,
    this.deltaPercent,
    this.comparisonLabel,
    this.increaseIsGood = false,
  });

  final String label;
  final Color color;
  final double amount;
  final VoidCallback? onTap;

  /// Percent change vs [comparisonLabel]'s period — null (or a null
  /// [comparisonLabel]) shows no delta at all, e.g. for a custom date range.
  final double? deltaPercent;

  /// e.g. "last month".
  final String? comparisonLabel;

  /// Whether an increase should read as positive (green) rather than the
  /// default negative (red) — true for income-like tiles.
  final bool increaseIsGood;
}

/// One side of the category breakdown toggle — e.g. "Spending"/"Income", or
/// "Group total"/"Your share".
class AnalysisCategorySide {
  const AnalysisCategorySide({required this.label, required this.side, this.increaseIsGood = false});

  final String label;
  final AnalysisSide side;

  /// Whether a category's amount increasing should read as positive (green)
  /// rather than the default negative (red) — true for income sides.
  final bool increaseIsGood;
}

/// The shared report layout: two stat tiles side by side (plus optional
/// extra content in the same card, e.g. personal analysis's Net Balance
/// row), then a category breakdown card with a toggle between two named
/// sides and a donut chart. Used by both the personal Analysis screen and
/// the group Reports tab — they differ only in which tiles/sides they feed
/// in, not in how any of it renders.
class AnalysisReportView extends StatelessWidget {
  const AnalysisReportView({
    super.key,
    required this.primaryTile,
    required this.secondaryTile,
    required this.firstSide,
    required this.secondSide,
    required this.showFirstSide,
    required this.onSideChanged,
    this.extra,
  });

  final AnalysisStatTile primaryTile;
  final AnalysisStatTile secondaryTile;
  final AnalysisCategorySide firstSide;
  final AnalysisCategorySide secondSide;

  /// Whether the category breakdown toggle is currently showing [firstSide]
  /// (true) or [secondSide] (false). Owned by the parent screen so it
  /// survives this widget being rebuilt for a new period.
  final bool showFirstSide;

  /// Invoked with the new toggle state when the user taps a side.
  final ValueChanged<bool> onSideChanged;

  /// Optional content rendered below the stat tiles inside the same card.
  /// Omitted entirely when null (the group report has no equivalent to
  /// personal analysis's Net Balance row).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final selected = showFirstSide ? firstSide : secondSide;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatTapTarget(
                      label: primaryTile.label,
                      color: primaryTile.color,
                      amount: primaryTile.amount,
                      onTap: primaryTile.onTap,
                      deltaPercent: primaryTile.deltaPercent,
                      comparisonLabel: primaryTile.comparisonLabel,
                      increaseIsGood: primaryTile.increaseIsGood,
                    ),
                  ),
                  Expanded(
                    child: StatTapTarget(
                      label: secondaryTile.label,
                      color: secondaryTile.color,
                      amount: secondaryTile.amount,
                      alignEnd: true,
                      onTap: secondaryTile.onTap,
                      deltaPercent: secondaryTile.deltaPercent,
                      comparisonLabel: secondaryTile.comparisonLabel,
                      increaseIsGood: secondaryTile.increaseIsGood,
                    ),
                  ),
                ],
              ),
              if (extra != null) ...[
                const SizedBox(height: AppSpacing.lg),
                extra!,
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Categories', style: AppTypography.sectionHeading.copyWith(color: ink)),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: sunken, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedToggleOption(
                        label: firstSide.label,
                        selected: showFirstSide,
                        onTap: () => onSideChanged(true),
                      ),
                    ),
                    Expanded(
                      child: SegmentedToggleOption(
                        label: secondSide.label,
                        selected: !showFirstSide,
                        onTap: () => onSideChanged(false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CategoryDonutChart(
                key: ValueKey(showFirstSide),
                categories: selected.side.byCategory,
                total: selected.side.total,
                increaseIsGood: selected.increaseIsGood,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
