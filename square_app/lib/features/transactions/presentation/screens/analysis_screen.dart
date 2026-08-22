import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/analysis_report_view.dart';
import '../../data/analysis_model.dart';
import '../analysis_provider.dart';
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

    return AnalysisReportView(
      primaryTile: AnalysisStatTile(
        label: 'SPENDING',
        color: AppColors.negative,
        amount: summary.spending.total,
        onTap: () => _openDrilldown(isSpending: true),
      ),
      secondaryTile: AnalysisStatTile(
        label: 'INCOME',
        color: AppColors.positive,
        amount: summary.income.total,
        onTap: () => _openDrilldown(isSpending: false),
      ),
      firstSide: AnalysisCategorySide(label: 'Spending', side: summary.spending),
      secondSide: AnalysisCategorySide(label: 'Income', side: summary.income),
      showFirstSide: _showSpendingCategories,
      onSideChanged: (v) => setState(() => _showSpendingCategories = v),
      extra: Container(
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
    );
  }

  void _openDrilldown({required bool isSpending}) {
    context.push(
      '/transactions/analysis-detail',
      extra: {'isSpending': isSpending, 'period': _period},
    );
  }
}
