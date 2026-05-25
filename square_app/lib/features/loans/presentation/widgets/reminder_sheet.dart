import 'package:flutter/material.dart';
import '../../../../features/transactions/data/loan_model.dart';
import '../../data/loans_repository.dart';

class ReminderSheet extends StatelessWidget {
  final Loan loan;
  final String token;
  final LoansRepository repository;

  const ReminderSheet({super.key, required this.loan, required this.token, required this.repository});

  static void show(BuildContext context, {required Loan loan, required String token, required LoansRepository repository}) {}

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
