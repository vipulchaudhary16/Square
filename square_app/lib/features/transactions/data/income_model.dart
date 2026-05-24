class Income {
  final String id;
  final String source;
  final double amount;
  final String description;
  final DateTime date;
  final String userId;
  final String categoryId;
  final String categoryName;

  Income({
    required this.id,
    required this.source,
    required this.amount,
    required this.description,
    required this.date,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['_id'] ?? json['id'] ?? '',
      source: json['source'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      userId: json['user_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'user_id': userId,
      'category_id': categoryId,
    };
  }
}
