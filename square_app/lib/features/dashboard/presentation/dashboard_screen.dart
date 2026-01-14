import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../transactions/presentation/widgets/premium_transaction_card.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false, // No back button on main tabs
        backgroundColor: Colors.transparent,
        actions: [
          // Profile Icon moved here
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () => context.go('/profile'),
              child: CircleAvatar(
                backgroundColor: AppColors.primary[100],
                radius: 16,
                child: Text(
                  'V',
                  style: TextStyle(
                    color: AppColors.primary[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          if (data == null) return const Center(child: Text('No data'));

          final netBalance = data.totalIncome - data.totalExpenses;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats Carousel
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    // Net Balance Card (Primary)
                    Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary[600]!,
                            AppColors.primary[800]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary[600]!.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  LucideIcons.wallet,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Net Balance',
                                style: TextStyle(
                                  color: Color(0xFFede9fe), // Primary-100
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹${netBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Inc: ₹${data.totalIncome.toStringAsFixed(0)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFddd6fe),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Exp: ₹${data.totalExpenses.toStringAsFixed(0)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFddd6fe),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Investments Card
                    _buildStatCard(
                      context,
                      title: 'Investments',
                      amount: data.totalInvested,
                      icon: LucideIcons.trendingUp,
                      color: Colors.blue,
                      subtext: 'Active investments',
                    ),

                    // Lent Card
                    _buildStatCard(
                      context,
                      title: 'Money Lent',
                      amount: data.lentAmount,
                      icon: LucideIcons.arrowLeftRight,
                      color: Colors.green,
                      subtext: 'To be received',
                    ),

                    // Borrowed Card
                    _buildStatCard(
                      context,
                      title: 'Borrowed',
                      amount: data.borrowedAmount,
                      icon: LucideIcons.arrowLeftRight,
                      color: Colors.red,
                      subtext: 'To be paid',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Chart Section
              GlassContainer(
                width: double.infinity,
                height: 350,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Trends',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.slate[800],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: LineChart(
                        // Switching to LineChart as easier to match "Area" look with fill
                        LineChartData(
                          gridData: FlGridData(show: false), // Clean look
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.slate[500]
                                          : AppColors.slate[400],
                                      fontSize: 10,
                                    ),
                                  );
                                },
                                interval: 5, // Show every 5th day
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            // Current Month Line
                            LineChartBarData(
                              spots: data.expenseGraph
                                  .map(
                                    (e) => FlSpot(
                                      e.day.toDouble(),
                                      e.currentMonth,
                                    ),
                                  )
                                  .toList(),
                              isCurved: true,
                              color: const Color(0xFF8884d8),
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF8884d8).withOpacity(0.2),
                              ),
                            ),
                            // Last Month Line
                            LineChartBarData(
                              spots: data.expenseGraph
                                  .map(
                                    (e) =>
                                        FlSpot(e.day.toDouble(), e.lastMonth),
                                  )
                                  .toList(),
                              isCurved: true,
                              color: const Color(0xFF82ca9d),
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF82ca9d).withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.slate[800],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/transactions'),
                    child: Text(
                      'View All',
                      style: TextStyle(color: AppColors.primary[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Transactions List
              if (data.recentExpenses.isEmpty)
                const Center(child: Text("No expenses yet"))
              else
                ...data.recentExpenses.map(
                  (e) => PremiumTransactionCard(
                    title: e.description.isNotEmpty ? e.description : 'Expense',
                    subtitle: e.category,
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
    required MaterialColor color,
    required String subtext,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color[500]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color[500], size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? AppColors.slate[400] : AppColors.slate[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.slate[800],
              ),
            ),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.slate[500] : AppColors.slate[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
