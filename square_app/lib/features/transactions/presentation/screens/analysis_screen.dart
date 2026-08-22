import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../data/analysis_model.dart';
import '../analysis_provider.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/period_selection.dart';
import '../widgets/period_selector.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  PeriodSelection _period = PeriodSelection.initial();
  bool _showSpendingCategories = true;

  String get _rangeKey => '${_period.apiStartDate}|${_period.apiEndDate}';

  @override
  Widget build(BuildContext context) {
    final analysisAsync = ref.watch(analysisProvider(_rangeKey));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(analysisProvider(_rangeKey));
        try {
          await ref.read(analysisProvider(_rangeKey).future);
        } catch (_) {}
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
        children: [
          PeriodSelector(
            selection: _period,
            onChanged: (p) => setState(() => _period = p),
            transactionCount: analysisAsync.value?.transactionCount ?? 0,
          ),
          const SizedBox(height: AppSpacing.lg),
          analysisAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => AppErrorState(
              message: err.toString(),
              onRetry: () => ref.invalidate(analysisProvider(_rangeKey)),
            ),
            data: (summary) => _buildContent(context, summary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AnalysisSummary summary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final selectedSide = _showSpendingCategories ? summary.spending : summary.income;

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
                    child: _CashflowTapTarget(
                      label: 'SPENDING',
                      color: AppColors.negative,
                      amount: summary.spending.total,
                      onTap: () => _openDrilldown(isSpending: true),
                    ),
                  ),
                  Expanded(
                    child: _CashflowTapTarget(
                      label: 'INCOME',
                      color: AppColors.positive,
                      amount: summary.income.total,
                      alignEnd: true,
                      onTap: () => _openDrilldown(isSpending: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                decoration: BoxDecoration(color: sunken, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Net Balance', style: AppTypography.body.copyWith(color: inkFaint)),
                    AmountText(
                      amount: summary.netBalance,
                      sign: AmountSign.neutral,
                      style: AppTypography.cardHeading.copyWith(color: ink),
                    ),
                  ],
                ),
              ),
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
                      child: _ToggleTab(
                        label: 'Spending',
                        selected: _showSpendingCategories,
                        onTap: () => setState(() => _showSpendingCategories = true),
                      ),
                    ),
                    Expanded(
                      child: _ToggleTab(
                        label: 'Income',
                        selected: !_showSpendingCategories,
                        onTap: () => setState(() => _showSpendingCategories = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CategoryDonutChart(
                key: ValueKey(_showSpendingCategories),
                categories: selectedSide.byCategory,
                total: selectedSide.total,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openDrilldown({required bool isSpending}) {
    context.push(
      '/transactions/analysis-detail',
      extra: {'isSpending': isSpending, 'period': _period},
    );
  }
}

class _CashflowTapTarget extends StatelessWidget {
  const _CashflowTapTarget({
    required this.label,
    required this.color,
    required this.amount,
    required this.onTap,
    this.alignEnd = false,
  });

  final String label;
  final Color color;
  final double amount;
  final bool alignEnd;
  final VoidCallback onTap;

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

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({required this.label, required this.selected, required this.onTap});
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
