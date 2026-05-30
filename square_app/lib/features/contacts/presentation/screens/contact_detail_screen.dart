import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../data/contact_model.dart';
import '../../data/contacts_repository.dart';
import '../contacts_provider.dart';
import '../../../../../features/transactions/data/loan_model.dart';

final _contactLoansProvider =
    FutureProvider.family<ContactLoansResult, String>(
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
      backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (result) => _buildBody(context, result, isDark),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ContactLoansResult result, bool isDark) {
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
            expandedHeight: 220,
            pinned: true,
            backgroundColor: isDark ? AppColors.slate[950] : Colors.white,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft,
                  color: isDark ? Colors.white : Colors.black),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(contact, net, isDark),
            ),
            bottom: TabBar(
              labelColor: isDark ? Colors.white : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: isDark ? Colors.white : Colors.black,
              tabs: [
                Tab(text: 'Active (${activeLoans.length})'),
                Tab(text: 'Settled (${settledLoans.length})'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _LoanList(loans: activeLoans, isDark: isDark),
            _LoanList(loans: settledLoans, isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Contact contact, Map<String, dynamic> net, bool isDark) {
    final isOwed = net['direction'] == 'owed_to_you';
    final amount = (net['amount'] as num? ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    isDark ? AppColors.slate[700] : AppColors.slate[200],
                child: Text(
                  contact.initials,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black)),
                  if (contact.phone != null)
                    Text(contact.phone!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  if (contact.onPlatform)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('On platform ✓',
                          style: TextStyle(
                              fontSize: 10, color: Colors.green)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isOwed
                  ? Colors.green.withOpacity(0.12)
                  : Colors.red.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOwed
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwed
                      ? '${contact.name} owes you'
                      : 'You owe ${contact.name}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  formatInr(amount),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isOwed ? Colors.green[600] : Colors.red[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanList extends StatelessWidget {
  final List<Loan> loans;
  final bool isDark;

  const _LoanList({required this.loans, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Center(
        child: Text('None',
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: loans.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => _LoanTile(loan: loans[i], isDark: isDark),
    );
  }
}

class _LoanTile extends StatelessWidget {
  final Loan loan;
  final bool isDark;

  const _LoanTile({required this.loan, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLent = loan.direction == 'lent';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: loan.isOverdue
              ? Colors.red[400]
              : loan.isPaid
                  ? Colors.green[600]
                  : Colors.amber[600],
        ),
      ),
      title: Text(
        loan.description ?? (isLent ? 'Lent' : 'Borrowed'),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        loan.dueDate != null
            ? 'Due ${DateFormat('dd/MM/yyyy').format(loan.dueDate!)}'
            : 'No due date',
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatInr(loan.amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isLent ? Colors.green[600] : Colors.red[400],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: loan.isOverdue
                  ? Colors.red.withOpacity(0.12)
                  : loan.isPaid
                      ? Colors.green.withOpacity(0.12)
                      : Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              loan.isOverdue ? 'Overdue' : loan.status,
              style: TextStyle(
                fontSize: 9,
                color: loan.isOverdue
                    ? Colors.red[400]
                    : loan.isPaid
                        ? Colors.green[600]
                        : Colors.amber[600],
              ),
            ),
          ),
        ],
      ),
      onTap: () => context.push('/loans/${loan.id}'),
    );
  }
}
