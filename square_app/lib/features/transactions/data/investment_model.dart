class Investment {
  final String id;
  final String type;
  final double amountInvested;
  final double currentValue;
  final String description;
  final DateTime date;
  final String userId;

  Investment({
    required this.id,
    required this.type,
    required this.amountInvested,
    required this.currentValue,
    required this.description,
    required this.date,
    required this.userId,
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
    };
  }
}
