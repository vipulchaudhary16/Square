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
  });

  final String label;
  final Color color;
  final double amount;
  final VoidCallback? onTap;
}

/// One side of the category breakdown toggle — e.g. "Spending"/"Income", or
/// "Group total"/"Your share".
class AnalysisCategorySide {
  const AnalysisCategorySide({required this.label, required this.side});

  final String label;
  final AnalysisSide side;
}

/// The shared report layout: two stat tiles side by side (plus optional
/// extra content in the same card, e.g. personal analysis's Net Balance
/// row), then a category breakdown card with a toggle between two named
/// sides and a donut chart. Used by both the personal Analysis screen and
/// the group Reports tab — they differ only in which tiles/sides they feed
/// in, not in how any of it renders.
class AnalysisReportView extends StatefulWidget {
  const AnalysisReportView({
    super.key,
    required this.primaryTile,
    required this.secondaryTile,
    required this.firstSide,
    required this.secondSide,
    this.extra,
  });

  final AnalysisStatTile primaryTile;
  final AnalysisStatTile secondaryTile;
  final AnalysisCategorySide firstSide;
  final AnalysisCategorySide secondSide;

  /// Optional content rendered below the stat tiles inside the same card.
  /// Omitted entirely when null (the group report has no equivalent to
  /// personal analysis's Net Balance row).
  final Widget? extra;

  @override
  State<AnalysisReportView> createState() => _AnalysisReportViewState();
}

class _AnalysisReportViewState extends State<AnalysisReportView> {
  bool _showFirstSide = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final selected = _showFirstSide ? widget.firstSide : widget.secondSide;

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
                      label: widget.primaryTile.label,
                      color: widget.primaryTile.color,
                      amount: widget.primaryTile.amount,
                      onTap: widget.primaryTile.onTap,
                    ),
                  ),
                  Expanded(
                    child: StatTapTarget(
                      label: widget.secondaryTile.label,
                      color: widget.secondaryTile.color,
                      amount: widget.secondaryTile.amount,
                      alignEnd: true,
                      onTap: widget.secondaryTile.onTap,
                    ),
                  ),
                ],
              ),
              if (widget.extra != null) ...[
                const SizedBox(height: AppSpacing.lg),
                widget.extra!,
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
                        label: widget.firstSide.label,
                        selected: _showFirstSide,
                        onTap: () => setState(() => _showFirstSide = true),
                      ),
                    ),
                    Expanded(
                      child: SegmentedToggleOption(
                        label: widget.secondSide.label,
                        selected: !_showFirstSide,
                        onTap: () => setState(() => _showFirstSide = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CategoryDonutChart(
                key: ValueKey(_showFirstSide),
                categories: selected.side.byCategory,
                total: selected.side.total,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
