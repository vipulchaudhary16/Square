class Expense {
  final String id;
  final String description;
  final double amount;
  final String categoryId;
  final String categoryName;
  final String? categoryColor;
  final DateTime date;
  final String? groupId;
  final String? groupName;
  final String payerId;
  final String? payerName;
  final List<String> participants;

  final String? splitType;
  final Map<String, double>? splits;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    this.categoryColor,
    required this.date,
    this.groupId,
    this.groupName,
    required this.payerId,
    this.payerName,
    required this.participants,
    this.splitType,
    this.splits,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['_id'] ?? json['id'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? 'General',
      categoryColor: json['category_color'],
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      groupId: json['group_id'],
      groupName: json['group_name'],
      payerId: json['payer_id'] ?? '',
      payerName: json['payer_name'],
      participants: List<String>.from(json['participants'] ?? []),
      splitType: json['split_type'],
      splits: (json['splits'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'category_id': categoryId,
      'category_name': categoryName,
      'date': date.toIso8601String(),
      if (groupId != null) 'group_id': groupId,
      'payer_id': payerId,
      'participants': participants,
      if (splitType != null) 'split_type': splitType,
      if (splits != null) 'splits': splits,
    };
  }
}
