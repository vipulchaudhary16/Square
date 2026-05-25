class Loan {
  final String id;
  final String lenderUserId;
  final String? borrowerUserId;
  final String contactId;
  final String contactName;
  final String direction; // 'lent' or 'borrowed'
  final double amount;
  final String status; // 'PENDING', 'PARTIAL', 'PAID'
  final String confirmationStatus; // 'pending', 'confirmed', 'disputed'
  final DateTime date;
  final DateTime? dueDate;
  final String interestMode; // 'none', 'from_start', 'penalty'
  final double? interestRate;
  final String? interestPeriod;
  final String? interestBasis;
  final String? description;
  final String categoryId;
  final String categoryName;
  final DateTime createdAt;
  final double outstanding;
  final double accruedInterest;
  final double totalDue;

  Loan({
    required this.id,
    required this.lenderUserId,
    this.borrowerUserId,
    required this.contactId,
    required this.contactName,
    required this.direction,
    required this.amount,
    required this.status,
    required this.confirmationStatus,
    required this.date,
    this.dueDate,
    required this.interestMode,
    this.interestRate,
    this.interestPeriod,
    this.interestBasis,
    this.description,
    this.categoryId = '',
    this.categoryName = '',
    required this.createdAt,
    double? outstanding,
    double? accruedInterest,
    double? totalDue,
  })  : outstanding = outstanding ?? amount,
        accruedInterest = accruedInterest ?? 0.0,
        totalDue = totalDue ?? amount;

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        id: json['id'] ?? '',
        lenderUserId: json['lender_user_id'] ?? '',
        borrowerUserId: json['borrower_user_id'],
        contactId: json['contact_id'] ?? '',
        contactName: json['contact_name'] ?? '',
        direction: json['direction'] ?? 'lent',
        amount: (json['amount'] ?? 0).toDouble(),
        status: json['status'] ?? 'PENDING',
        confirmationStatus: json['confirmation_status'] ?? 'pending',
        date: DateTime.parse(
            json['date'] ?? DateTime.now().toIso8601String()),
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'])
            : null,
        interestMode: json['interest_mode'] ?? 'none',
        interestRate: json['interest_rate']?.toDouble(),
        interestPeriod: json['interest_period'],
        interestBasis: json['interest_basis'],
        description: json['description'],
        categoryId: json['category_id'] ?? '',
        categoryName: json['category_name'] ?? '',
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
        outstanding: (json['outstanding'] as num?)?.toDouble(),
        accruedInterest: (json['accrued_interest'] as num?)?.toDouble(),
        totalDue: (json['total_due'] as num?)?.toDouble(),
      );

  bool get isPending => status == 'PENDING';
  bool get isPaid => status == 'PAID';
  bool get isPartial => status == 'PARTIAL';
  bool get isOverdue =>
      dueDate != null && DateTime.now().isAfter(dueDate!) && !isPaid;
}
