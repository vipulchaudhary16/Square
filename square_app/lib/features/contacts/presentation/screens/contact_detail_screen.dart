import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../data/contact_model.dart';
import '../contacts_provider.dart';
import '../../../../features/transactions/data/loan_model.dart';

final _contactLoansProvider = FutureProvider.autoDispose
    .family<ContactLoansResult, String>((ref, contactId) async {
      return ref.read(contactsRepositoryProvider).getContactLoans(contactId);
    });

class ContactDetailScreen extends ConsumerWidget {
  final String contactId;
  const ContactDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_contactLoansProvider(contactId));

    return Scaffold(
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorState(message: e.toString()),
        data: (result) => _ContactDetailBody(
          result: result,
          onPop: () => context.pop(),
          contactId: contactId,
        ),
      ),
    );
  }
}

class _ContactDetailBody extends StatelessWidget {
  final ContactLoansResult result;
  final VoidCallback onPop;
  final String contactId;

  const _ContactDetailBody({
    required this.result,
    required this.onPop,
    required this.contactId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final line = isDark ? AppColors.lineDark : AppColors.line;

    final contact = result.contact;
    final loans = result.loans;
    final net = result.netBalance;
    final activeLoans = loans.where((l) => l.status != 'PAID').toList();
    final settledLoans = loans.where((l) => l.status == 'PAID').toList();

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 248,
            pinned: true,
            leading: AppIconButton(icon: Icons.arrow_back, onPressed: onPop),
            actions: [
              AppIconButton(
                icon: Icons.edit,
                iconSize: 16,
                onPressed: () async {
                  await context.push(
                    '/contacts/${contact.id}/edit',
                    extra: contact,
                  );
                },
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _Header(contact: contact, net: net),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: line)),
                ),
                child: TabBar(
                  labelColor: ink,
                  unselectedLabelColor: inkFaint,
                  indicatorColor: ink,
                  indicatorWeight: 2,
                  labelStyle: AppTypography.bodyEmphasis.copyWith(fontSize: 13),
                  unselectedLabelStyle: AppTypography.body.copyWith(
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: 'Active (${activeLoans.length})'),
                    Tab(text: 'Settled (${settledLoans.length})'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _LoanList(loans: activeLoans, contactId: contactId),
            _LoanList(loans: settledLoans, contactId: contactId),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Contact contact;
  final Map<String, dynamic> net;

  const _Header({required this.contact, required this.net});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final isOwed = net['direction'] == 'owed_to_you';
    final amount = (net['amount'] as num? ?? 0).toDouble();
    final accent = AppColors.categoryAccent(contact.name);
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, topPad, AppSpacing.xl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    contact.initials,
                    style: AppTypography.screenTitle.copyWith(
                      color: accent,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: AppTypography.sectionHeading.copyWith(
                        color: ink,
                        fontSize: 18,
                      ),
                    ),
                    if (contact.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        contact.phone!,
                        style: AppTypography.bodyMuted.copyWith(
                          color: inkFaint,
                        ),
                      ),
                    ],
                    if (contact.onPlatform) ...[
                      const SizedBox(height: AppSpacing.xs),
                      AppChip(
                        label: 'On platform',
                        status: AppChipStatus.positive,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _BalanceCard(contact: contact, amount: amount, isOwed: isOwed),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Contact contact;
  final double amount;
  final bool isOwed;

  const _BalanceCard({
    required this.contact,
    required this.amount,
    required this.isOwed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final color = isOwed ? AppColors.positive : AppColors.negative;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOwed ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwed
                      ? '${contact.name} owes you'
                      : 'You owe ${contact.name}',
                  style: AppTypography.caption.copyWith(color: inkFaint),
                ),
                const SizedBox(height: 1),
                AmountText(
                  amount: amount,
                  sign: isOwed ? AmountSign.positive : AmountSign.negative,
                  showSignPrefix: false,
                  style: AppTypography.amountLarge,
                ),
              ],
            ),
          ),
          Text(
            'net balance',
            style: AppTypography.caption.copyWith(color: inkFaint),
          ),
        ],
      ),
    );
  }
}

class _LoanList extends ConsumerWidget {
  final List<Loan> loans;
  final String contactId;

  const _LoanList({required this.loans, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (loans.isEmpty) {
      return const Center(
        child: AppEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No loans here',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_contactLoansProvider(contactId));
        await ref.read(_contactLoansProvider(contactId).future);
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        itemCount: loans.length,
        itemBuilder: (_, i) => _LoanCard(loan: loans[i]),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;

  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final isLent = loan.direction == 'lent';
    final accentColor = isLent ? AppColors.positive : AppColors.negative;

    final title = (loan.description != null && loan.description!.isNotEmpty)
        ? loan.description!
        : '${isLent ? 'Lent' : 'Borrowed'} · ${DateFormat('dd MMM yyyy').format(loan.date)}';

    final status = loan.isOverdue
        ? AppChipStatus.negative
        : loan.isPaid
        ? AppChipStatus.positive
        : AppChipStatus.warning;
    final statusLabel = loan.isOverdue ? 'Overdue' : loan.status;

    return AppInteractiveCard(
      onTap: () => context.push('/loans/${loan.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLent ? Icons.north_east_rounded : Icons.south_west_rounded,
              size: 18,
              color: accentColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardHeading.copyWith(
                    color: ink,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    AppChip(label: statusLabel, status: status),
                    if (loan.dueDate != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Due ${DateFormat('dd MMM').format(loan.dueDate!)}',
                        style: AppTypography.caption.copyWith(
                          color: loan.isOverdue ? AppColors.negative : inkFaint,
                        ),
                      ),
                    ],
                    if (loan.interestMode != 'none' &&
                        loan.interestRate != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${loan.interestRate!.toStringAsFixed(loan.interestRate! % 1 == 0 ? 0 : 1)}%',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatInr(loan.amount),
                style: AppTypography.amountInline.copyWith(color: accentColor),
              ),
              if (loan.interestMode != 'none' && loan.totalDue != loan.amount)
                Text(
                  formatInr(loan.totalDue),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
