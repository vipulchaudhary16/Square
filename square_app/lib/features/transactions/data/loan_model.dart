class Loan {
  final String id;
  final String type; // 'LENT' or 'BORROWED'
  final double amount;
  final String counterpartyName;
  final String status; // 'PENDING' or 'PAID'
  final DateTime date;
  final String userId;
  final String? description;

  Loan({
    required this.id,
    required this.type,
    required this.amount,
    required this.counterpartyName,
    required this.status,
    required this.date,
    required this.userId,
    this.description,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? 'LENT',
      amount: (json['amount'] ?? 0).toDouble(),
      counterpartyName: json['counterparty_name'] ?? '',
      status: json['status'] ?? 'PENDING',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      userId: json['user_id'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'counterparty_name': counterpartyName,
      'status': status,
      'date': date.toIso8601String(),
      'user_id': userId,
      if (description != null) 'description': description,
    };
  }
}
