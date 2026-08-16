import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/group_model.dart';
import '../../data/group_repository.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/amount_text.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/data/user_repository.dart';
import '../../../auth/data/user_model.dart';
import '../../../expense/data/expense_model.dart';
import '../../../expense/presentation/widgets/expense_card.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../groups_provider.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(groupDetailsProvider(widget.groupId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    return Scaffold(
      appBar: AppBar(
        title: Text(detailsAsync.value?.group.name ?? 'Group Details'),
        actions: [
          AppIconButton(
            icon: Icons.person_add_outlined,
            onPressed: () => _showAddMemberModal(context, widget.groupId),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: ink,
          unselectedLabelColor: inkFaint,
          indicatorColor: ink,
          labelStyle: AppTypography.bodyEmphasis,
          unselectedLabelStyle: AppTypography.body,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => AppErrorState(message: err.toString()),
        data: (details) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildExpensesTab(context, details),
              _buildBalancesTab(context, details),
              _buildMembersTab(context, details),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/transactions/add-expense', extra: {'groupId': widget.groupId});
        },
        backgroundColor: ink,
        elevation: 0,
        child: Icon(Icons.add, color: isDark ? AppColors.surfaceSunkenDark : AppColors.surface),
      ),
    );
  }

  Widget _buildExpensesTab(BuildContext context, GroupDetails details) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final currentUserId = ref.watch(authProvider).value?.id;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groupExpensesProvider("${details.group.id}|$_searchQuery"));
        ref.invalidate(groupDetailsProvider(details.group.id));
        try {
          await ref.read(groupExpensesProvider("${details.group.id}|$_searchQuery").future);
        } catch (_) {}
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: _GroupSummaryCard(
                details: details,
                currentUserId: currentUserId,
                onShowMore: () => _tabController.animateTo(1),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarHeaderDelegate(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Container(
                  decoration: BoxDecoration(
                    color: sunken,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: line),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: AppTypography.body.copyWith(color: ink),
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      hintStyle: AppTypography.body.copyWith(color: inkFaint),
                      prefixIcon: Icon(Icons.search, size: 18, color: inkFaint),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, size: 16, color: inkFaint),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _ExpenseListSliver(groupId: details.group.id, searchQuery: _searchQuery),
        ],
      ),
    );
  }

  void _showAddMemberModal(BuildContext context, String groupId) {
    final searchController = TextEditingController();
    final emailController = TextEditingController();
    bool isSearching = false;
    bool isInviting = false;
    List<User> searchResults = [];

    AppBottomSheet.show(
      context,
      title: 'Add Member',
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final ink = isDark ? AppColors.inkDark : AppColors.ink;
            final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
            final line = isDark ? AppColors.lineDark : AppColors.line;
            final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search by name or email', style: AppTypography.label.copyWith(color: inkFaint)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: line),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: TextField(
                            controller: searchController,
                            style: AppTypography.body.copyWith(color: ink),
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: AppTypography.body.copyWith(color: inkFaint),
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppIconButton(
                        icon: Icons.search,
                        filled: true,
                        onPressed: () async {
                          if (searchController.text.trim().isEmpty) return;
                          setState(() => isSearching = true);
                          try {
                            final results = await ref
                                .read(userRepositoryProvider)
                                .searchUsers(searchController.text.trim());
                            setState(() => searchResults = results);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
                            }
                          } finally {
                            setState(() => isSearching = false);
                          }
                        },
                      ),
                    ],
                  ),
                  if (isSearching) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  ],
                  if (searchResults.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(color: sunken, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        separatorBuilder: (_, __) => Divider(color: line, height: 1),
                        itemBuilder: (context, index) {
                          final user = searchResults[index];
                          final displayName = user.firstName.isEmpty
                              ? user.email.split('@').first
                              : '${user.firstName} ${user.lastName}';
                          return ListTile(
                            title: Text(displayName, style: AppTypography.body.copyWith(color: ink)),
                            subtitle: Text(user.email, style: AppTypography.caption.copyWith(color: inkFaint)),
                            trailing: AppIconButton(
                              icon: Icons.add,
                              size: 32,
                              iconSize: 16,
                              onPressed: () async {
                                try {
                                  await ref.read(groupRepositoryProvider).addMember(groupId, user.id);
                                  if (context.mounted) {
                                    ref.invalidate(groupDetailsProvider(groupId));
                                    context.pop();
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added!')));
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add: $e')));
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Divider(color: line),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Or invite by email', style: AppTypography.label.copyWith(color: inkFaint)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: line),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTypography.body.copyWith(color: ink),
                            decoration: InputDecoration(
                              hintText: 'friend@example.com',
                              hintStyle: AppTypography.body.copyWith(color: inkFaint),
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: PrimaryButton(
                          text: '',
                          icon: Icons.mail_outline,
                          isLoading: isInviting,
                          onPressed: () async {
                            if (emailController.text.trim().isEmpty) return;
                            setState(() => isInviting = true);
                            try {
                              await ref.read(groupRepositoryProvider).inviteUser(groupId, emailController.text.trim());
                              if (context.mounted) {
                                context.pop();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation sent!')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                              }
                            } finally {
                              setState(() => isInviting = false);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBalancesTab(BuildContext context, GroupDetails details) {
    final currentUserId = ref.watch(authProvider).value?.id;
    final sortedDebts = _sortDebtsInvolvingUserFirst(details.debts, currentUserId);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groupExpensesProvider("${details.group.id}|$_searchQuery"));
        ref.invalidate(groupDetailsProvider(details.group.id));
        try {
          await ref.read(groupDetailsProvider(details.group.id).future);
        } catch (_) {}
      },
      child: details.debts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: AppEmptyState(icon: Icons.check_circle, title: 'Everyone is settled up'),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: sortedDebts.length,
              itemBuilder: (context, index) {
                final debt = sortedDebts[index];
                final fromUser = details.members.firstWhere(
                  (m) => m.id == debt.from,
                  orElse: () => GroupMember(id: '', username: 'Unknown', email: ''),
                );
                final toUser = details.members.firstWhere(
                  (m) => m.id == debt.to,
                  orElse: () => GroupMember(id: '', username: 'Unknown', email: ''),
                );
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final ink = isDark ? AppColors.inkDark : AppColors.ink;
                final line = debtLineText(debt, currentUserId, fromUser, toUser);

                return AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      _Avatar(name: fromUser.displayName),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          line.text,
                          style: AppTypography.body.copyWith(color: ink),
                        ),
                      ),
                      AmountText(
                        amount: debt.amount,
                        sign: line.sign,
                        showSignPrefix: false,
                        style: AppTypography.amountInline,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMembersTab(BuildContext context, GroupDetails details) {
    final currentUserId = ref.watch(authProvider).value?.id;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groupExpensesProvider("${details.group.id}|$_searchQuery"));
        ref.invalidate(groupDetailsProvider(details.group.id));
        try {
          await ref.read(groupDetailsProvider(details.group.id).future);
        } catch (_) {}
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: details.members.length,
        itemBuilder: (context, index) {
          final member = details.members[index];
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final ink = isDark ? AppColors.inkDark : AppColors.ink;
          final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
          final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
          final isYou = member.id == currentUserId;

          return AppCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _Avatar(name: member.displayName),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.displayName, style: AppTypography.cardHeading.copyWith(color: ink)),
                      const SizedBox(height: 2),
                      Text(
                        member.email,
                        style: AppTypography.bodyMuted.copyWith(color: inkFaint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isYou) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(color: sunken, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: Text(
                      'You',
                      style: AppTypography.caption.copyWith(color: inkFaint, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Debt> _sortDebtsInvolvingUserFirst(List<Debt> debts, String? currentUserId) =>
      sortDebtsInvolvingUserFirst(debts, currentUserId);
}

({String text, AmountSign sign}) debtLineText(
  Debt debt,
  String? currentUserId,
  GroupMember fromUser,
  GroupMember toUser,
) {
  if (debt.from == currentUserId) {
    return (text: 'You owe ${toUser.displayName}', sign: AmountSign.negative);
  } else if (debt.to == currentUserId) {
    return (text: '${fromUser.displayName} owes you', sign: AmountSign.positive);
  } else {
    return (text: '${fromUser.displayName} owes ${toUser.displayName}', sign: AmountSign.neutral);
  }
}

List<Debt> sortDebtsInvolvingUserFirst(List<Debt> debts, String? currentUserId) {
  if (currentUserId == null) return debts;
  final mine = <Debt>[];
  final others = <Debt>[];
  for (final debt in debts) {
    if (debt.from == currentUserId || debt.to == currentUserId) {
      mine.add(debt);
    } else {
      others.add(debt);
    }
  }
  return [...mine, ...others];
}

class _GroupSummaryCard extends StatelessWidget {
  const _GroupSummaryCard({
    required this.details,
    required this.currentUserId,
    required this.onShowMore,
  });

  final GroupDetails details;
  final String? currentUserId;
  final VoidCallback onShowMore;

  GroupMember _memberFor(String id) => details.members.firstWhere(
        (m) => m.id == id,
        orElse: () => GroupMember(id: '', username: 'Unknown', email: ''),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;

    if (details.debts.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 18, color: inkFaint),
            const SizedBox(width: AppSpacing.sm),
            Text('Everyone is settled up', style: AppTypography.bodyMuted.copyWith(color: inkFaint)),
          ],
        ),
      );
    }

    final sortedDebts = sortDebtsInvolvingUserFirst(details.debts, currentUserId);
    final shown = sortedDebts.take(3).toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final debt in shown) ...[
            _buildDebtLine(debt, ink),
            if (debt != shown.last) const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: onShowMore,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Show more', style: AppTypography.bodyEmphasis.copyWith(color: ink)),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward, size: 14, color: ink),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtLine(Debt debt, Color ink) {
    final fromUser = _memberFor(debt.from);
    final toUser = _memberFor(debt.to);
    final line = debtLineText(debt, currentUserId, fromUser, toUser);

    return Row(
      children: [
        Expanded(
          child: Text(line.text, style: AppTypography.body.copyWith(color: ink), overflow: TextOverflow.ellipsis),
        ),
        AmountText(
          amount: debt.amount,
          sign: line.sign,
          showSignPrefix: false,
          style: AppTypography.amountInline,
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.categoryAccent(name);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: accent.withValues(alpha: isDark ? 0.22 : 0.12), shape: BoxShape.circle),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppTypography.bodyEmphasis.copyWith(color: accent),
        ),
      ),
    );
  }
}

class _SearchBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SearchBarHeaderDelegate({required this.child, required this.backgroundColor});

  final Widget child;
  final Color backgroundColor;

  static const double _extent = 80;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(color: backgroundColor, child: child);
  }

  @override
  bool shouldRebuild(covariant _SearchBarHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.backgroundColor != backgroundColor;
  }
}

class _ExpenseListSliver extends ConsumerWidget {
  final String groupId;
  final String searchQuery;

  const _ExpenseListSliver({required this.groupId, required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider("$groupId|$searchQuery"));
    final currentUser = ref.watch(authProvider).value;

    return expensesAsync.when(
      loading: () => SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const AppSkeletonRow(),
            childCount: 4,
          ),
        ),
      ),
      error: (err, stack) => SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(groupExpensesProvider("$groupId|$searchQuery")),
        ),
      ),
      data: (expenses) {
        if (expenses.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: searchQuery.isEmpty ? 'No expenses yet' : 'No matches',
                message: searchQuery.isEmpty
                    ? 'Expenses recorded in this group will show up here.'
                    : 'Nothing matches "$searchQuery"',
              ),
            ),
          );
        }

        final grouped = _groupByDate(expenses);
        final flatList = <dynamic>[];
        for (final entry in grouped.entries) {
          flatList.add(entry.key);
          flatList.addAll(entry.value);
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = flatList[index];
                if (item is String) return _buildDateHeader(context, item, isFirst: index == 0);
                final expense = item as Expense;
                return ExpenseCard(
                  expense: expense,
                  currentUserId: currentUser?.id ?? '',
                  onTap: () => context.push('/transactions/expenses/${expense.id}'),
                );
              },
              childCount: flatList.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(BuildContext context, String label, {bool isFirst = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, isFirst ? 0 : AppSpacing.lg, 4, AppSpacing.sm),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.label.copyWith(color: isDark ? AppColors.inkFaintDark : AppColors.inkFaint),
      ),
    );
  }

  Map<String, List<Expense>> _groupByDate(List<Expense> expenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<Expense>>{};

    for (final expense in expenses) {
      final date = expense.date;
      final day = DateTime(date.year, date.month, date.day);
      final String label;
      if (day == today) {
        label = 'Today';
      } else if (day == yesterday) {
        label = 'Yesterday';
      } else if (now.year == date.year) {
        label = DateFormat('MMMM d').format(date);
      } else {
        label = DateFormat('MMMM d, y').format(date);
      }
      (groups[label] ??= []).add(expense);
    }
    return groups;
  }
}
