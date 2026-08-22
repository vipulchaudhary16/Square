import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/analysis_model.dart';

/// Donut chart for a category breakdown. Colors reuse the app's fixed
/// categorical accent set (AppColors.categoryAccent) for consistency with
/// avatars/category chips elsewhere — segments are also always labeled and
/// legended (never color-alone), since that palette has one CVD-marginal
/// adjacent pair.
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({super.key, required this.categories, required this.total});

  final List<CategoryBreakdown> categories;
  final double total;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;

    if (categories.isEmpty || total <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(
          child: Text('No data for this period', style: AppTypography.bodyMuted.copyWith(color: inkFaint)),
        ),
      );
    }

    // Fold long tails into "Other" beyond the top 6, keeping the legend
    // readable and matching the app's fixed 6-color accent set.
    final sorted = [...categories]..sort((a, b) => b.amount.compareTo(a.amount));
    final top = sorted.take(6).toList();
    final otherAmount = sorted.skip(6).fold<double>(0, (sum, c) => sum + c.amount);

    final segments = [
      ...top,
      if (otherAmount > 0)
        CategoryBreakdown(
          categoryId: '__other__',
          categoryName: 'Other',
          amount: otherAmount,
          percent: total > 0 ? (otherAmount / total * 100) : 0,
        ),
    ];

    Color colorFor(CategoryBreakdown c) => c.categoryId == '__other__'
        ? inkFaint
        : AppColors.resolveCategoryColor(c.categoryName, colorHex: c.categoryColor);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 56,
              sections: segments.map((c) {
                return PieChartSectionData(
                  value: c.amount,
                  color: colorFor(c),
                  radius: 32,
                  showTitle: c.percent >= 8,
                  title: c.percent >= 8
                      ? '${formatInr(c.amount)}\n(${c.percent.toStringAsFixed(1)}%)'
                      : '',
                  titleStyle: AppTypography.caption.copyWith(color: surface, fontWeight: FontWeight.w700),
                  borderSide: BorderSide(color: surface, width: 2),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: segments.map((c) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: colorFor(c), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      c.categoryName,
                      style: AppTypography.body.copyWith(color: ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${formatInr(c.amount)} (${c.percent.toStringAsFixed(1)}%)',
                    style: AppTypography.caption.copyWith(color: inkFaint),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
