import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/auth/data/user_model.dart';
import '../../../features/transactions/data/loan_model.dart';
import '../../../features/transactions/data/loan_payment_model.dart';
import '../data/loans_repository.dart';
import 'widgets/interest_timeline_card.dart';
import 'widgets/record_payment_sheet.dart';
import 'widgets/reminder_sheet.dart';

final _loanDetailProvider = FutureProvider.family<LoanDetail, String>(
  (ref, loanId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return ref.read(loansRepositoryProvider).getLoan(token, loanId);
  },
);

class LoanDetailScreen extends ConsumerWidget {
  final String loanId;
  const LoanDetailScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_loanDetailProvider(loanId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF7F7F7),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) => _LoanDetailBody(
          detail: detail,
          loanId: loanId,
          isDark: isDark,
          onRefresh: () => ref.invalidate(_loanDetailProvider(loanId)),
        ),
      ),
    );
  }
}

class _LoanDetailBody extends ConsumerStatefulWidget {
  final LoanDetail detail;
  final String loanId;
  final bool isDark;
  final VoidCallback onRefresh;

  const _LoanDetailBody({
    required this.detail,
    required this.loanId,
    required this.isDark,
    required this.onRefresh,
  });

  @override
  ConsumerState<_LoanDetailBody> createState() => _LoanDetailBodyState();
}

class _LoanDetailBodyState extends ConsumerState<_LoanDetailBody> {
  late final Future<String?> _userIdFuture;

  @override
  void initState() {
    super.initState();
    _userIdFuture = _loadUserId();
  }

  Future<String?> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData == null) return null;
    return User.fromJson(jsonDecode(userData) as Map<String, dynamic>).id;
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final loan = detail.loan;
    final isLent = loan.direction == 'lent';
    final accentColor = isLent ? Colors.green[600]! : Colors.red[400]!;
    final isDark = widget.isDark;
    final onRefresh = widget.onRefresh;

    return FutureBuilder<String?>(
      future: _userIdFuture,
      builder: (context, snap) {
        final currentUserId = snap.data;
        final isLender = currentUserId != null &&
            loan.lenderUserId == currentUserId;
        final isBorrower = currentUserId != null &&
            loan.borrowerUserId == currentUserId;

        return Scaffold(
          backgroundColor:
              isDark ? Colors.black : const Color(0xFFF7F7F7),
          appBar: AppBar(
            backgroundColor:
                isDark ? Colors.black : const Color(0xFFF7F7F7),
            elevation: 0,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft,
                  color: isDark ? Colors.white : Colors.black),
              onPressed: () => context.pop(),
            ),
            title: Text(
              loan.contactName,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            actions: [
              if (isLender)
                IconButton(
                  icon: Icon(LucideIcons.bell,
                      color: isDark ? Colors.white70 : Colors.black54),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('token') ?? '';
                    if (context.mounted) {
                      ReminderSheet.show(
                        context,
                        loan: loan,
                        token: token,
                        repository: ref.read(loansRepositoryProvider),
                      );
                    }
                  },
                ),
            ],
          ),
          floatingActionButton: isLender && loan.status != 'PAID'
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('token') ?? '';
                    if (context.mounted) {
                      await RecordPaymentSheet.show(
                        context,
                        loan: loan,
                        token: token,
                        repository: ref.read(loansRepositoryProvider),
                      );
                      onRefresh();
                    }
                  },
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  icon: const Icon(LucideIcons.checkCircle, size: 18),
                  label: const Text('Record Payment',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _AmountCard(loan: loan, accentColor: accentColor, isDark: isDark),
              if (loan.interestMode != 'none')
                InterestTimelineCard(
                  timeline: detail.interestTimeline,
                  accruedInterest: loan.accruedInterest,
                  isDark: isDark,
                ),
              if (isBorrower && loan.status != 'PAID')
                FutureBuilder<String>(
                  future: () async {
                    final prefs = await SharedPreferences.getInstance();
                    return prefs.getString('token') ?? '';
                  }(),
                  builder: (context, snap) {
                    final token = snap.data ?? '';
                    return _ConfirmationBar(
                      loan: loan,
                      token: token,
                      repository: ref.read(loansRepositoryProvider),
                      onUpdated: onRefresh,
                    );
                  },
                ),
              _SectionHeader(label: 'Payment History', isDark: isDark),
              if (detail.payments.isEmpty)
                _EmptyPayments(isDark: isDark)
              else
                ...detail.payments.map(
                  (p) => _PaymentTile(payment: p, isDark: isDark),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AmountCard extends StatelessWidget {
  final Loan loan;
  final Color accentColor;
  final bool isDark;

  const _AmountCard(
      {required this.loan, required this.accentColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: loan.direction == 'lent'
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  loan.direction == 'lent' ? 'LENT' : 'BORROWED',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accentColor),
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: loan.status),
              if (loan.confirmationStatus == 'confirmed')
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Confirmed',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue)),
                ),
              if (loan.confirmationStatus == 'disputed')
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Disputed',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatInr(loan.amount),
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: accentColor),
          ),
          if (loan.description != null && loan.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(loan.description!,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black45)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoPair(
                  label: 'Date',
                  value: DateFormat('dd MMM y').format(loan.date),
                  isDark: isDark),
              if (loan.dueDate != null) ...[
                const SizedBox(width: 24),
                _InfoPair(
                    label: 'Due',
                    value: DateFormat('dd MMM y').format(loan.dueDate!),
                    isDark: isDark),
              ],
            ],
          ),
          if (loan.interestMode != 'none') ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoPair(
                    label: 'Outstanding',
                    value: formatInr(loan.outstanding),
                    isDark: isDark),
                const SizedBox(width: 24),
                _InfoPair(
                    label: 'Total Due',
                    value: formatInr(loan.totalDue),
                    isDark: isDark,
                    highlight: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'PAID':
        color = Colors.green[600]!;
        break;
      case 'PARTIAL':
        color = Colors.blue[400]!;
        break;
      default:
        color = Colors.amber[600]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _InfoPair extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;

  const _InfoPair(
      {required this.label,
      required this.value,
      required this.isDark,
      this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white38 : Colors.black38)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight
                    ? Colors.orange[400]
                    : (isDark ? Colors.white70 : Colors.black87))),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF3A3A3A),
        ),
      ),
    );
  }
}

class _EmptyPayments extends StatelessWidget {
  final bool isDark;
  const _EmptyPayments({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No payments recorded yet',
          style: TextStyle(
              color: isDark ? Colors.white30 : Colors.black26,
              fontSize: 13),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final LoanPayment payment;
  final bool isDark;
  const _PaymentTile({required this.payment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.checkCircle,
                size: 16, color: Colors.green[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.note ?? 'Payment',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  DateFormat('dd MMM y').format(payment.paidAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            formatInr(payment.amount),
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.green[600]),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationBar extends StatelessWidget {
  final Loan loan;
  final String token;
  final LoansRepository repository;
  final VoidCallback onUpdated;

  const _ConfirmationBar({
    required this.loan,
    required this.token,
    required this.repository,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (loan.confirmationStatus != 'pending') return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirm this loan?',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.blue)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await repository.updateConfirmation(
                        token, loan.id, 'confirmed');
                    onUpdated();
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[600],
                      side: BorderSide(color: Colors.green[600]!)),
                  child: const Text('Confirm'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await repository.updateConfirmation(
                        token, loan.id, 'disputed');
                    onUpdated();
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[400],
                      side: BorderSide(color: Colors.red[400]!)),
                  child: const Text('Dispute'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
