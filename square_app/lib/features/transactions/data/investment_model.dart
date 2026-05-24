class Investment {
  final String id;
  final String type;
  final double amountInvested;
  final double currentValue;
  final String description;
  final DateTime date;
  final String userId;
  final String categoryId;
  final String categoryName;

  Investment({
    required this.id,
    required this.type,
    required this.amountInvested,
    required this.currentValue,
    required this.description,
    required this.date,
    required this.userId,
    this.categoryId = '',
    this.categoryName = '',
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      amountInvested: (json['amount_invested'] ?? 0).toDouble(),
      currentValue: (json['current_value'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      userId: json['user_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount_invested': amountInvested,
      'current_value': currentValue,
      'description': description,
      'date': date.toIso8601String(),
      'user_id': userId,
      'category_id': categoryId,
    };
  }
}
