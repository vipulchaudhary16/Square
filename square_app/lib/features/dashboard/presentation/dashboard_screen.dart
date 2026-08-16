import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
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
    final showTrends = ref
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
        title: Text('Dashboard', style: AppTypography.screenTitle.copyWith(color: ink)),
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
                    color: isDark ? AppColors.surfaceSunkenDark : AppColors.surface,
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
            return const AppEmptyState(icon: Icons.grid_view_outlined, title: 'No data yet');
          }

          final netBalance = data.totalIncome - data.totalExpenses;

          return ListView(
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
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: isDark ? AppColors.surfaceSunkenDark : AppColors.surface,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Net balance',
                                style: AppTypography.bodyMuted.copyWith(
                                  color: (isDark ? AppColors.surfaceSunkenDark : AppColors.surface)
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                          AmountText(
                            amount: netBalance,
                            showPaise: true,
                            showSignPrefix: false,
                            tooltipBgColor: isDark ? AppColors.surfaceSunkenDark : AppColors.surface,
                            tooltipTextColor: ink,
                            style: AppTypography.amountLarge.copyWith(
                              color: isDark ? AppColors.surfaceSunkenDark : AppColors.surface,
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
                                    color: (isDark ? AppColors.surfaceSunkenDark : AppColors.surface)
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
                                    color: (isDark ? AppColors.surfaceSunkenDark : AppColors.surface)
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
                        Text('Expense trends', style: AppTypography.sectionHeading.copyWith(color: ink)),
                        const SizedBox(height: AppSpacing.lg),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) => Text(
                                      value.toInt().toString(),
                                      style: AppTypography.caption.copyWith(
                                        color: isDark ? AppColors.inkFaintDark : AppColors.inkFaint,
                                      ),
                                    ),
                                    interval: 5,
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: data.expenseGraph
                                      .map((e) => FlSpot(e.day.toDouble(), e.currentMonth))
                                      .toList(),
                                  isCurved: true,
                                  color: ink,
                                  barWidth: 2.5,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(show: true, color: ink.withValues(alpha: 0.08)),
                                ),
                                LineChartBarData(
                                  spots: data.expenseGraph
                                      .map((e) => FlSpot(e.day.toDouble(), e.lastMonth))
                                      .toList(),
                                  isCurved: true,
                                  color: isDark ? AppColors.inkFaintDark : AppColors.inkFaint,
                                  barWidth: 2,
                                  dotData: FlDotData(show: false),
                                ),
                              ],
                            ),
                          ),
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
                  Text('Recent transactions', style: AppTypography.sectionHeading.copyWith(color: ink)),
                  GhostButton(text: 'View all', compact: true, onPressed: () => context.go('/transactions')),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              if (data.recentExpenses.isEmpty)
                const AppEmptyState(icon: Icons.receipt_long_outlined, title: 'No expenses yet')
              else
                ...data.recentExpenses.map(
                  (e) => PremiumTransactionCard(
                    title: e.description.isNotEmpty ? e.description : 'Expense',
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
            AmountText(amount: amount, sign: sign, showSignPrefix: false, style: AppTypography.amountLarge),
            Text(subtext, style: AppTypography.caption.copyWith(color: inkFaint)),
          ],
        ),
      ),
    );
  }
}
