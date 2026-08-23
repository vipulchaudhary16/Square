import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/analysis_report_view.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/pinned_header_delegate.dart';
import '../../../transactions/presentation/widgets/period_selection.dart';
import '../../../transactions/presentation/widgets/period_selector.dart';
import '../groups_provider.dart';

class GroupReportsScreen extends ConsumerStatefulWidget {
  const GroupReportsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupReportsScreen> createState() => _GroupReportsScreenState();
}

class _GroupReportsScreenState extends ConsumerState<GroupReportsScreen> {
  PeriodSelection _reportPeriod = PeriodSelection.initial();
  bool _showGroupTotalCategories = true;

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId;
    final previousPeriod = _reportPeriod.comparisonLabel != null ? _reportPeriod.previous() : null;
    final rangeKey =
        '$groupId|${_reportPeriod.apiStartDate}|${_reportPeriod.apiEndDate}|${previousPeriod?.apiStartDate ?? ''}|${previousPeriod?.apiEndDate ?? ''}';
    final analysisAsync = ref.watch(groupAnalysisProvider(rangeKey));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupAnalysisProvider(rangeKey));
          try {
            await ref.read(groupAnalysisProvider(rangeKey).future);
          } catch (_) {}
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: PinnedHeaderDelegate(
                extent: 96,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
                  child: PeriodSelector(
                    selection: _reportPeriod,
                    onChanged: (p) => setState(() => _reportPeriod = p),
                    transactionCount: analysisAsync.value?.totalExpense.count ?? 0,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
              sliver: SliverToBoxAdapter(
                child: analysisAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => AppErrorState(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(groupAnalysisProvider(rangeKey)),
                  ),
                  data: (summary) => AnalysisReportView(
                    primaryTile: AnalysisStatTile(
                      label: 'TOTAL EXPENSE',
                      color: AppColors.negative,
                      amount: summary.totalExpense.total,
                      onTap: () => context.push(
                        '/transactions/analysis-detail',
                        extra: {
                          'isSpending': true,
                          'period': _reportPeriod,
                          'groupId': groupId,
                          'allGroupExpenses': true,
                        },
                      ),
                      deltaPercent: summary.totalExpense.deltaPercent,
                      comparisonLabel: _reportPeriod.comparisonLabel,
                    ),
                    secondaryTile: AnalysisStatTile(
                      label: 'YOUR SHARE',
                      color: AppColors.negative,
                      amount: summary.yourShare.total,
                      onTap: () => context.push(
                        '/transactions/analysis-detail',
                        extra: {'isSpending': true, 'period': _reportPeriod, 'groupId': groupId},
                      ),
                      deltaPercent: summary.yourShare.deltaPercent,
                      comparisonLabel: _reportPeriod.comparisonLabel,
                    ),
                    firstSide: AnalysisCategorySide(label: 'Group total', side: summary.totalExpense),
                    secondSide: AnalysisCategorySide(label: 'Your share', side: summary.yourShare),
                    showFirstSide: _showGroupTotalCategories,
                    onSideChanged: (v) => setState(() => _showGroupTotalCategories = v),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
