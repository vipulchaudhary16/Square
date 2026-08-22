class CategoryBreakdown {
  final String categoryId;
  final String categoryName;
  final String? categoryColor;
  final double amount;
  final double percent;

  /// Percent change vs this same category in the compare period — null if no
  /// comparison was requested, or the category had a zero total last period.
  final double? deltaPercent;

  CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    this.categoryColor,
    required this.amount,
    required this.percent,
    this.deltaPercent,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? 'Uncategorized',
      categoryColor: json['category_color'],
      amount: (json['amount'] ?? 0).toDouble(),
      percent: (json['percent'] ?? 0).toDouble(),
      deltaPercent: (json['delta_percent'] as num?)?.toDouble(),
    );
  }
}

class AnalysisSide {
  final double total;
  final int count;
  final List<CategoryBreakdown> byCategory;

  /// Percent change vs the compare period, when the request asked for one —
  /// null if no comparison was requested, or if the compare period had a
  /// zero total (nothing meaningful to divide by).
  final double? deltaPercent;

  AnalysisSide({
    required this.total,
    required this.count,
    required this.byCategory,
    this.deltaPercent,
  });

  factory AnalysisSide.fromJson(Map<String, dynamic> json) {
    return AnalysisSide(
      total: (json['total'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
      byCategory: (json['by_category'] as List<dynamic>? ?? [])
          .map((e) => CategoryBreakdown.fromJson(e))
          .toList(),
      deltaPercent: (json['delta_percent'] as num?)?.toDouble(),
    );
  }
}

class AnalysisSummary {
  final AnalysisSide spending;
  final AnalysisSide income;

  AnalysisSummary({required this.spending, required this.income});

  double get netBalance => income.total - spending.total;
  int get transactionCount => spending.count + income.count;

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisSummary(
      spending: AnalysisSide.fromJson(json['spending'] ?? {}),
      income: AnalysisSide.fromJson(json['income'] ?? {}),
    );
  }
}
