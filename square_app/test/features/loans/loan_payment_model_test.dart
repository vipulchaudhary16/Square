import 'package:flutter_test/flutter_test.dart';
import 'package:square_app/features/transactions/data/loan_payment_model.dart';

void main() {
  group('LoanPayment.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': '42',
        'loan_id': '7',
        'amount': 1500.0,
        'paid_at': '2026-05-20T10:00:00.000Z',
        'note': 'First repayment',
        'created_at': '2026-05-20T10:01:00.000Z',
      };
      final p = LoanPayment.fromJson(json);
      expect(p.id, '42');
      expect(p.loanId, '7');
      expect(p.amount, 1500.0);
      expect(p.paidAt, DateTime.parse('2026-05-20T10:00:00.000Z'));
      expect(p.note, 'First repayment');
    });

    test('note is nullable', () {
      final json = {
        'id': '1', 'loan_id': '2', 'amount': 500.0,
        'paid_at': '2026-05-01T00:00:00.000Z',
        'created_at': '2026-05-01T00:00:00.000Z',
      };
      final p = LoanPayment.fromJson(json);
      expect(p.note, isNull);
    });
  });
}
