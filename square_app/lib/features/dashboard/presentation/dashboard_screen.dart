import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../data/dashboard_model.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../feature_flags/presentation/feature_flags_provider.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../../transactions/presentation/widgets/premium_transaction_card.dart';
import '../../../../shared/widgets/menu_button.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(dashboardProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final user = ref.watch(authProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final showTrends =
        ref
            .watch(featureFlagsProvider)
            .value
            ?.any((f) => f.key == 'show_expense_trends_chart' && f.value) ??
        false;

    final initial = (user?.firstName.isNotEmpty == true)
        ? user!.firstName[0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        title: Text(
          'Dashboard',
          style: AppTypography.screenTitle.copyWith(color: ink),
        ),
        automaticallyImplyLeading: false, // No back button on main tabs
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: InkWell(
              onTap: () => context.go('/profile'),
              borderRadius: BorderRadius.circular(16),
              child: CircleAvatar(
                backgroundColor: ink,
                radius: 16,
                child: Text(
                  initial,
                  style: AppTypography.bodyEmphasis.copyWith(
                    color: isDark
                        ? AppColors.surfaceSunkenDark
                        : AppColors.surface,
                  ),
                ),
              ),
            ),
          ),
          const MenuButton(),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: dashboardState.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            AppSkeletonRow(),
            AppSkeletonRow(),
            AppSkeletonRow(),
          ],
        ),
        error: (err, stack) => AppErrorState(
          message: '$err',
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (data) {
          if (data == null) {
            return const AppEmptyState(
              icon: Icons.grid_view_outlined,
              title: 'No data yet',
            );
          }

          final netBalance = data.totalIncome - data.totalExpenses;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              await ref.read(dashboardProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Stats Carousel
                SizedBox(
                  height: 172,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      // Net Balance Card (Primary)
                      Container(
                        width: 268,
                        margin: const EdgeInsets.only(right: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: isDark
                                        ? AppColors.surfaceSunkenDark
                                        : AppColors.surface,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Net balance',
                                  style: AppTypography.bodyMuted.copyWith(
                                    color:
                                        (isDark
                                                ? AppColors.surfaceSunkenDark
                                                : AppColors.surface)
                                            .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            AmountText(
                              amount: netBalance,
                              showPaise: true,
                              showSignPrefix: false,
                              tooltipBgColor: isDark
                                  ? AppColors.surfaceSunkenDark
                                  : AppColors.surface,
                              tooltipTextColor: ink,
                              style: AppTypography.amountLarge.copyWith(
                                color: isDark
                                    ? AppColors.surfaceSunkenDark
                                    : AppColors.surface,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Inc ${formatInr(data.totalIncome)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      color:
                                          (isDark
                                                  ? AppColors.surfaceSunkenDark
                                                  : AppColors.surface)
                                              .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    'Exp ${formatInr(data.totalExpenses)}',
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      color:
                                          (isDark
                                                  ? AppColors.surfaceSunkenDark
                                                  : AppColors.surface)
                                              .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      _buildStatCard(
                        context,
                        title: 'Investments',
                        amount: data.totalInvested,
                        icon: Icons.trending_up,
                        sign: AmountSign.neutral,
                        subtext: 'Active investments',
                      ),
                      _buildStatCard(
                        context,
                        title: 'Money lent',
                        amount: data.lentAmount,
                        icon: Icons.swap_horiz,
                        sign: AmountSign.positive,
                        subtext: 'To be received',
                      ),
                      _buildStatCard(
                        context,
                        title: 'Borrowed',
                        amount: data.borrowedAmount,
                        icon: Icons.swap_horiz,
                        sign: AmountSign.negative,
                        subtext: 'To be paid',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Chart Section
                if (showTrends) ...[
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: SizedBox(
                      height: 300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Expense trends',
                                style: AppTypography.sectionHeading.copyWith(
                                  color: ink,
                                ),
                              ),
                              _buildTrendLegend(isDark),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Expanded(
                            child: _buildExpenseTrendsChart(data, ink, isDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Recent Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent transactions',
                      style: AppTypography.sectionHeading.copyWith(color: ink),
                    ),
                    GhostButton(
                      text: 'View all',
                      compact: true,
                      onPressed: () => context.go('/transactions'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                if (data.recentExpenses.isEmpty)
                  const AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No expenses yet',
                  )
                else
                  ...data.recentExpenses.map(
                    (e) => PremiumTransactionCard(
                      title: e.description.isNotEmpty
                          ? e.description
                          : 'Expense',
                      subtitle: e.categoryName,
                      amount: e.amount,
                      date: e.date,
                      type: TransactionType.expense,
                      category: null,
                      isPositive: false,
                      onTap: () => context.push(
                        '/transactions/expenses/${e.id}',
                        extra: e,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required double amount,
    required IconData icon,
    required AmountSign sign,
    required String subtext,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return Container(
      width: 188,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: ink, size: 16),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(color: inkFaint),
                  ),
                ),
              ],
            ),
            AmountText(
              amount: amount,
              sign: sign,
              showSignPrefix: false,
              style: AppTypography.amountLarge,
            ),
            Text(
              subtext,
              style: AppTypography.caption.copyWith(color: inkFaint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendLegend(bool isDark) {
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final muted = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;
    final labelColor = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendItem(
          swatchColor: ink,
          dashed: false,
          label: 'This month',
          labelColor: labelColor,
        ),
        const SizedBox(width: AppSpacing.md),
        _legendItem(
          swatchColor: muted,
          dashed: true,
          label: 'Last month',
          labelColor: labelColor,
        ),
      ],
    );
  }

  Widget _legendItem({
    required Color swatchColor,
    required bool dashed,
    required String label,
    required Color labelColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 2,
          child: dashed
              ? Row(
                  children: List.generate(
                    3,
                    (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 2 : 0),
                        color: swatchColor,
                      ),
                    ),
                  ),
                )
              : DecoratedBox(decoration: BoxDecoration(color: swatchColor)),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption.copyWith(color: labelColor)),
      ],
    );
  }

  Widget _buildExpenseTrendsChart(DashboardData data, Color ink, bool isDark) {
    final muted = isDark ? AppColors.inkMutedDark : AppColors.inkMuted;
    final faint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final cardSurface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final onTooltip = isDark ? AppColors.surfaceSunkenDark : AppColors.surface;

    final currentSpots = data.expenseGraph
        .where((e) => e.currentMonth != null)
        .map((e) => FlSpot(e.day.toDouble(), e.currentMonth!))
        .toList();
    final lastSpots = data.expenseGraph
        .map((e) => FlSpot(e.day.toDouble(), e.lastMonth))
        .toList();
    final maxDay = data.expenseGraph.isEmpty
        ? 31.0
        : data.expenseGraph.last.day.toDouble();

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: maxDay,
        minY: 0,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                if (day != 1 && day % 5 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '$day',
                    style: AppTypography.caption.copyWith(color: faint),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            getTooltipColor: (_) => ink,
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final label = spot.barIndex == 0 ? 'This month' : 'Last month';
              return LineTooltipItem(
                '$label\n${formatInr(spot.y)}',
                AppTypography.caption.copyWith(
                  color: onTooltip,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              );
            }).toList(),
          ),
          getTouchedSpotIndicator: (barData, spotIndexes) =>
              spotIndexes.map((_) {
                return TouchedSpotIndicatorData(
                  FlLine(color: line, strokeWidth: 1),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                          radius: 4,
                          color: bar.color ?? ink,
                          strokeWidth: 2,
                          strokeColor: cardSurface,
                        ),
                  ),
                );
              }).toList(),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: currentSpots,
            isCurved: true,
            curveSmoothness: 0.2,
            preventCurveOverShooting: true,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            color: ink,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) =>
                  barData.spots.isNotEmpty && spot == barData.spots.last,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: ink,
                strokeWidth: 2,
                strokeColor: cardSurface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: ink.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: lastSpots,
            isCurved: true,
            curveSmoothness: 0.2,
            preventCurveOverShooting: true,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            color: muted,
            barWidth: 2,
            dashArray: const [6, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
