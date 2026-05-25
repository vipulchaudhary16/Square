import 'package:flutter/material.dart';
import '../../../../features/transactions/data/loan_model.dart';
import '../../data/loans_repository.dart';

class RecordPaymentSheet extends StatelessWidget {
  final Loan loan;
  final String token;
  final LoansRepository repository;

  const RecordPaymentSheet({super.key, required this.loan, required this.token, required this.repository});

  static Future<bool?> show(BuildContext context, {required Loan loan, required String token, required LoansRepository repository}) {
    return showModalBottomSheet<bool>(
      context: context,
      builder: (_) => RecordPaymentSheet(loan: loan, token: token, repository: repository),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
