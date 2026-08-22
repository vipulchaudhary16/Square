import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../transactions/data/loan_model.dart';
import '../../transactions/data/loan_payment_model.dart';

class LoanDetail {
  final Loan loan;
  final List<LoanPayment> payments;
  final List<Map<String, dynamic>> interestTimeline;

  LoanDetail({
    required this.loan,
    required this.payments,
    required this.interestTimeline,
  });
}

class LoansRepository {
  final Dio _dio;

  LoansRepository(this._dio);

  Future<LoanDetail> getLoan(String loanId) async {
    try {
      final res = await _dio.get('/loans/$loanId');
      final data = res.data as Map<String, dynamic>;
      final loan = Loan.fromJson(data['loan']);
      final payments = (data['payments'] as List? ?? [])
          .map((j) => LoanPayment.fromJson(j as Map<String, dynamic>))
          .toList();
      final timeline = (data['interest_timeline'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      return LoanDetail(
        loan: loan,
        payments: payments,
        interestTimeline: timeline,
      );
    } catch (e) {
      throw Exception('Failed to fetch loan: $e');
    }
  }

  Future<Map<String, dynamic>> recordPayment(
    String loanId, {
    required double amount,
    required DateTime paidAt,
    String? note,
    bool addInterestToIncome = false,
  }) async {
    try {
      final res = await _dio.post(
        '/loans/$loanId/payments',
        data: {
          'amount': amount,
          'paid_at': paidAt.toIso8601String(),
          if (note != null) 'note': note,
          'add_interest_to_income': addInterestToIncome,
        },
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to record payment: $e');
    }
  }

  Future<void> setReminder(
    String loanId, {
    required DateTime remindAt,
    bool nudgeBorrower = false,
    bool viaPush = true,
    bool viaEmail = true,
    bool viaSms = false,
  }) async {
    try {
      await _dio.post(
        '/loans/$loanId/reminders',
        data: {
          'remind_at': remindAt.toUtc().toIso8601String(),
          'nudge_borrower': nudgeBorrower,
          'via_push': viaPush,
          'via_email': viaEmail,
          'via_sms': viaSms,
        },
      );
    } catch (e) {
      throw Exception('Failed to set reminder: $e');
    }
  }

  Future<Map<String, dynamic>> updateConfirmation(
    String loanId,
    String confirmationStatus,
  ) async {
    try {
      final res = await _dio.patch(
        '/loans/$loanId/confirmation',
        data: {'confirmation_status': confirmationStatus},
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to update confirmation: $e');
    }
  }
}

final loansRepositoryProvider = Provider(
  (ref) => LoansRepository(ref.watch(apiClientProvider)),
);
