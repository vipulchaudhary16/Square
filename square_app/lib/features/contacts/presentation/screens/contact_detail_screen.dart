import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../data/contact_model.dart';
import '../contacts_provider.dart';
import '../../../../../features/transactions/data/loan_model.dart';

final _contactLoansProvider =
    FutureProvider.autoDispose.family<ContactLoansResult, String>(
  (ref, contactId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return ref.read(contactsRepositoryProvider).getContactLoans(token, contactId);
  },
);

class ContactDetailScreen extends ConsumerWidget {
  final String contactId;
  const ContactDetailScreen({super.key, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_contactLoansProvider(contactId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (result) => _ContactDetailBody(
          result: result,
          isDark: isDark,
          onPop: () => context.pop(),
          contactId: contactId,
        ),
      ),
    );
  }
}

class _ContactDetailBody extends StatelessWidget {
  final ContactLoansResult result;
  final bool isDark;
  final VoidCallback onPop;
  final String contactId;

  const _ContactDetailBody({
    required this.result,
    required this.isDark,
    required this.onPop,
    required this.contactId,
  });

  @override
  Widget build(BuildContext context) {
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
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft,
                  color: isDark ? Colors.white : Colors.black),
              onPressed: onPop,
            ),
            actions: [
              IconButton(
                icon: Icon(LucideIcons.pencil,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.black54),
                onPressed: () async {
                  await context.push('/contacts/${contact.id}/edit',
                      extra: contact);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _Header(
                contact: contact,
                net: net,
                isDark: isDark,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 0.5,
                    ),
                  ),
                ),
                child: TabBar(
                  labelColor: isDark ? Colors.white : Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: isDark ? Colors.white : Colors.black,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
            _LoanList(loans: activeLoans, isDark: isDark, contactId: contactId),
            _LoanList(loans: settledLoans, isDark: isDark, contactId: contactId),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Contact contact;
  final Map<String, dynamic> net;
  final bool isDark;

  const _Header({required this.contact, required this.net, required this.isDark});

  Color get _avatarColor {
    final colors = [
      const Color(0xFF6366F1), const Color(0xFF8B5CF6), const Color(0xFFEC4899),
      const Color(0xFF0EA5E9), const Color(0xFF10B981), const Color(0xFFF59E0B),
    ];
    final idx = contact.name.codeUnitAt(0) % colors.length;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final isOwed = net['direction'] == 'owed_to_you';
    final amount = (net['amount'] as num? ?? 0).toDouble();
    final color = _avatarColor;
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 0),
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
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    contact.initials,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (contact.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        contact.phone!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                    if (contact.onPlatform) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.checkCircle,
                              size: 11, color: Colors.green[500]),
                          const SizedBox(width: 4),
                          Text(
                            'On platform',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BalanceCard(
            contact: contact,
            amount: amount,
            isOwed: isOwed,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Contact contact;
  final double amount;
  final bool isOwed;
  final bool isDark;

  const _BalanceCard({
    required this.contact,
    required this.amount,
    required this.isOwed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOwed ? Colors.green[600]! : Colors.red[400]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
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
              isOwed ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwed
                      ? '${contact.name} owes you'
                      : 'You owe ${contact.name}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  formatInr(amount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'net balance',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanList extends ConsumerWidget {
  final List<Loan> loans;
  final bool isDark;
  final String contactId;

  const _LoanList({required this.loans, required this.isDark, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.fileX,
                size: 32, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 10),
            Text(
              'No loans here',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: loans.length,
        itemBuilder: (_, i) => _LoanCard(loan: loans[i], isDark: isDark),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final bool isDark;

  const _LoanCard({required this.loan, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLent = loan.direction == 'lent';
    final accentColor = isLent ? Colors.green[600]! : Colors.red[400]!;

    final title = (loan.description != null && loan.description!.isNotEmpty)
        ? loan.description!
        : '${isLent ? 'Lent' : 'Borrowed'} · ${DateFormat('dd MMM yyyy').format(loan.date)}';

    final statusColor = loan.isOverdue
        ? Colors.red[400]!
        : loan.isPaid
            ? Colors.green[600]!
            : Colors.amber[600]!;
    final statusLabel = loan.isOverdue ? 'Overdue' : loan.status;

    return GestureDetector(
      onTap: () => context.push('/loans/${loan.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: loan.isOverdue
              ? Border.all(color: Colors.red.withValues(alpha: 0.25))
              : null,
        ),
        child: Row(
          children: [
            // Direction indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLent ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                size: 18,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      if (loan.dueDate != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Due ${DateFormat('dd MMM').format(loan.dueDate!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: loan.isOverdue
                                ? Colors.red[400]
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                        ),
                      ],
                      if (loan.interestMode != 'none' &&
                          loan.interestRate != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${loan.interestRate!.toStringAsFixed(loan.interestRate! % 1 == 0 ? 0 : 1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatInr(loan.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: accentColor,
                  ),
                ),
                if (loan.interestMode != 'none' && loan.totalDue != loan.amount)
                  Text(
                    formatInr(loan.totalDue),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[400],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight,
                size: 14,
                color: isDark ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }
}
