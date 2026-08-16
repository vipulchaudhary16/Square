import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/auth/data/user_model.dart';
import '../../../features/transactions/data/loan_model.dart';
import '../../../features/transactions/data/loan_payment_model.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_icon_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../data/loans_repository.dart';
import 'widgets/interest_timeline_card.dart';
import 'widgets/record_payment_sheet.dart';
import 'widgets/reminder_sheet.dart';

final _loanDetailProvider = FutureProvider.autoDispose.family<LoanDetail, String>(
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
      backgroundColor: isDark ? AppColors.surfaceSunkenDark : AppColors.surfaceSunken,
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
    final isDark = widget.isDark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final onRefresh = widget.onRefresh;

    return FutureBuilder<String?>(
      future: _userIdFuture,
      builder: (context, snap) {
        final currentUserId = snap.data;
        final isLender = currentUserId != null && loan.lenderUserId == currentUserId;
        final isBorrower = currentUserId != null && loan.borrowerUserId == currentUserId;

        return Scaffold(
          backgroundColor: isDark ? AppColors.surfaceSunkenDark : AppColors.surfaceSunken,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.surfaceSunkenDark : AppColors.surfaceSunken,
            elevation: 0,
            leading: AppIconButton(icon: Icons.arrow_back, onPressed: () => context.pop()),
            title: Text(loan.contactName, style: AppTypography.screenTitle.copyWith(color: ink, fontSize: 18)),
            actions: [
              if (isLender) ...[
                AppIconButton(
                  icon: Icons.edit,
                  onPressed: () async {
                    final refreshed = await context.push<bool>('/loans/${loan.id}/edit', extra: loan);
                    if (refreshed == true) onRefresh();
                  },
                ),
                AppIconButton(
                  icon: Icons.notifications_outlined,
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('token') ?? '';
                    if (context.mounted) {
                      ReminderSheet.show(context, loan: loan, token: token, repository: ref.read(loansRepositoryProvider));
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
          floatingActionButton: isLender && loan.status != 'PAID'
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('token') ?? '';
                    if (context.mounted) {
                      await RecordPaymentSheet.show(context, loan: loan, token: token, repository: ref.read(loansRepositoryProvider));
                      onRefresh();
                    }
                  },
                  backgroundColor: AppColors.ink,
                  foregroundColor: isDark ? AppColors.surfaceSunkenDark : AppColors.surface,
                  elevation: 0,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: Text('Record Payment', style: AppTypography.button.copyWith(color: isDark ? AppColors.surfaceSunkenDark : AppColors.surface)),
                )
              : null,
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_loanDetailProvider(widget.loanId));
              await ref.read(_loanDetailProvider(widget.loanId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                _AmountCard(loan: loan, isLent: isLent, isDark: isDark),
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
                  ...detail.payments.map((p) => _PaymentTile(payment: p, isDark: isDark)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AmountCard extends StatelessWidget {
  final Loan loan;
  final bool isLent;
  final bool isDark;

  const _AmountCard({required this.loan, required this.isLent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return AppCard(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppChip(label: isLent ? 'LENT' : 'BORROWED', status: isLent ? AppChipStatus.positive : AppChipStatus.negative),
              const SizedBox(width: AppSpacing.xs),
              _StatusChip(status: loan.status),
              if (loan.confirmationStatus == 'confirmed') ...[
                const SizedBox(width: AppSpacing.xs),
                const AppChip(label: 'Confirmed', status: AppChipStatus.positive),
              ],
              if (loan.confirmationStatus == 'disputed') ...[
                const SizedBox(width: AppSpacing.xs),
                const AppChip(label: 'Disputed', status: AppChipStatus.warning),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AmountText(
            amount: loan.amount,
            sign: isLent ? AmountSign.positive : AmountSign.negative,
            showSignPrefix: false,
            style: AppTypography.displayAmount,
          ),
          if (loan.description != null && loan.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(loan.description!, style: AppTypography.bodyMuted.copyWith(color: inkFaint)),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _InfoPair(label: 'Date', value: DateFormat('dd MMM y').format(loan.date), ink: ink, inkFaint: inkFaint),
              if (loan.dueDate != null) ...[
                const SizedBox(width: AppSpacing.xl),
                _InfoPair(label: 'Due', value: DateFormat('dd MMM y').format(loan.dueDate!), ink: ink, inkFaint: inkFaint),
              ],
            ],
          ),
          if (loan.interestMode != 'none') ...[
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: isDark ? AppColors.lineDark : AppColors.line),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _InfoPair(label: 'Outstanding', value: formatInr(loan.outstanding), ink: ink, inkFaint: inkFaint),
                const SizedBox(width: AppSpacing.xl),
                _InfoPair(label: 'Total Due', value: formatInr(loan.totalDue), ink: ink, inkFaint: inkFaint, highlight: true),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: isDark ? AppColors.lineDark : AppColors.line),
            const SizedBox(height: AppSpacing.md),
            _InterestDetailsRow(loan: loan, isDark: isDark),
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
    final chipStatus = switch (status) {
      'PAID' => AppChipStatus.positive,
      'PARTIAL' => AppChipStatus.neutral,
      _ => AppChipStatus.warning,
    };
    return AppChip(label: status, status: chipStatus);
  }
}

class _InterestDetailsRow extends StatelessWidget {
  final Loan loan;
  final bool isDark;
  const _InterestDetailsRow({required this.loan, required this.isDark});

  String get _modeLabel {
    switch (loan.interestMode) {
      case 'from_start':
        return 'From start';
      case 'penalty':
        return 'Penalty';
      default:
        return loan.interestMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = <(String, String)>[
      if (loan.interestRate != null)
        ('Rate', '${loan.interestRate!.toStringAsFixed(loan.interestRate! % 1 == 0 ? 0 : 2)}%'),
      if (loan.interestPeriod != null)
        ('Per', '${loan.interestPeriod![0].toUpperCase()}${loan.interestPeriod!.substring(1)}'),
      if (loan.interestBasis != null)
        ('Calc', loan.interestBasis == 'total' ? 'Compound' : 'Simple'),
      ('Type', _modeLabel),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: chips.map((c) => _InterestChip(label: c.$1, value: c.$2, isDark: isDark)).toList(),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _InterestChip({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$label  ', style: AppTypography.caption.copyWith(color: inkFaint, fontSize: 10)),
            TextSpan(text: value, style: AppTypography.caption.copyWith(color: ink, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _InfoPair extends StatelessWidget {
  final String label;
  final String value;
  final Color ink;
  final Color inkFaint;
  final bool highlight;

  const _InfoPair({
    required this.label,
    required this.value,
    required this.ink,
    required this.inkFaint,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: inkFaint, fontSize: 10)),
        Text(
          value,
          style: AppTypography.bodyMuted.copyWith(
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? AppColors.warning : ink,
          ),
        ),
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
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Text(label.toUpperCase(), style: AppTypography.label.copyWith(color: inkFaint)),
    );
  }
}

class _EmptyPayments extends StatelessWidget {
  final bool isDark;
  const _EmptyPayments({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(child: Text('No payments recorded yet', style: AppTypography.bodyMuted.copyWith(color: inkFaint))),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final LoanPayment payment;
  final bool isDark;
  const _PaymentTile({required this.payment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.positiveSoft, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, size: 16, color: AppColors.positive),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.note ?? 'Payment', style: AppTypography.cardHeading.copyWith(color: ink, fontSize: 13)),
                Text(DateFormat('dd MMM y').format(payment.paidAt), style: AppTypography.caption.copyWith(color: inkFaint)),
              ],
            ),
          ),
          AmountText(amount: payment.amount, sign: AmountSign.positive, showSignPrefix: false, style: AppTypography.amountInline),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm this loan?', style: AppTypography.bodyEmphasis.copyWith(color: ink)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: 'Confirm',
                  onPressed: () async {
                    await repository.updateConfirmation(token, loan.id, 'confirmed');
                    onUpdated();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SecondaryButton(
                  text: 'Dispute',
                  onPressed: () async {
                    await repository.updateConfirmation(token, loan.id, 'disputed');
                    onUpdated();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
