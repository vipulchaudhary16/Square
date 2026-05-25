class LoanPayment {
  final String id;
  final String loanId;
  final double amount;
  final DateTime paidAt;
  final String? note;
  final DateTime createdAt;

  LoanPayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.paidAt,
    this.note,
    required this.createdAt,
  });

  factory LoanPayment.fromJson(Map<String, dynamic> json) => LoanPayment(
        id: json['id'] ?? '',
        loanId: json['loan_id'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        paidAt: DateTime.parse(json['paid_at']),
        note: json['note'],
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
      );
}
