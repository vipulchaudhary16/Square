class CategoryBreakdown {
  final String categoryId;
  final String categoryName;
  final String? categoryColor;
  final double amount;
  final double percent;

  CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    this.categoryColor,
    required this.amount,
    required this.percent,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? 'Uncategorized',
      categoryColor: json['category_color'],
      amount: (json['amount'] ?? 0).toDouble(),
      percent: (json['percent'] ?? 0).toDouble(),
    );
  }
}

class AnalysisSide {
  final double total;
  final int count;
  final List<CategoryBreakdown> byCategory;

  AnalysisSide({required this.total, required this.count, required this.byCategory});

  factory AnalysisSide.fromJson(Map<String, dynamic> json) {
    return AnalysisSide(
      total: (json['total'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
      byCategory: (json['by_category'] as List<dynamic>? ?? [])
          .map((e) => CategoryBreakdown.fromJson(e))
          .toList(),
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
