import 'package:square_app/features/expense/data/expense_model.dart';

class DashboardData {
  final double totalExpenses;
  final double totalIncome;
  final double totalInvested;
  final List<Expense> recentExpenses;
  final double lentAmount;
  final double borrowedAmount;
  final List<GraphPoint> expenseGraph;

  DashboardData({
    required this.totalExpenses,
    required this.totalIncome,
    required this.totalInvested,
    required this.recentExpenses,
    required this.lentAmount,
    required this.borrowedAmount,
    required this.expenseGraph,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalExpenses: (json['total_expenses'] ?? 0).toDouble(),
      totalIncome: (json['total_income'] ?? 0).toDouble(),
      totalInvested: (json['total_invested'] ?? 0).toDouble(),
      recentExpenses:
          (json['recent_expenses'] as List?)
              ?.map((e) => Expense.fromJson(e))
              .toList() ??
          [],
      lentAmount: (json['lent_amount'] ?? 0).toDouble(),
      borrowedAmount: (json['borrowed_amount'] ?? 0).toDouble(),
      expenseGraph:
          (json['expense_graph'] as List?)
              ?.map((e) => GraphPoint.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class GraphPoint {
  final int day;
  final double currentMonth;
  final double lastMonth;

  GraphPoint({
    required this.day,
    required this.currentMonth,
    required this.lastMonth,
  });

  factory GraphPoint.fromJson(Map<String, dynamic> json) {
    return GraphPoint(
      day: json['day'] ?? 0,
      currentMonth: (json['current_month'] ?? 0).toDouble(),
      lastMonth: (json['last_month'] ?? 0).toDouble(),
    );
  }
}
