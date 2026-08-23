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
import '../../../../shared/widgets/pinned_header_delegate.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/data/user_repository.dart';
import '../../../auth/data/user_model.dart';
import '../../../expense/presentation/widgets/expense_card.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../groups_provider.dart';
import '../widgets/settlement_log_row.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
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
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final line = isDark ? AppColors.lineDark : AppColors.line;
    final currentUserId = ref.watch(authProvider).value?.id;

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
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => AppErrorState(message: err.toString()),
        data: (details) {
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
                    child: _GroupHubHeader(details: details, currentUserId: currentUserId),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PinnedHeaderDelegate(
                    extent: 80,
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
}

/// Hub header shown above the search bar and expense feed: a single merged
/// net-balance card (tapping it opens the Balances screen — there is no
/// separate "Balances" tile) plus a row of Members/Reports tiles that each
/// push their own full screen.
class _GroupHubHeader extends StatelessWidget {
  const _GroupHubHeader({required this.details, required this.currentUserId});

  final GroupDetails details;
  final String? currentUserId;

  double get _netBalance {
    double net = 0;
    for (final debt in details.debts) {
      if (debt.to == currentUserId) net += debt.amount;
      if (debt.from == currentUserId) net -= debt.amount;
    }
    return net;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final net = _netBalance;
    final isSettled = net.abs() < 0.01;
    final isOwedToYou = net > 0;
    final balanceColor = isSettled ? inkFaint : (isOwedToYou ? AppColors.positive : AppColors.negative);
    final label = isSettled ? 'All settled up' : (isOwedToYou ? 'you are owed' : 'you owe');
    final formatted = NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(net.abs());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HubCard(
          onTap: () => context.push('/groups/${details.group.id}/balances'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: AppTypography.label.copyWith(color: inkFaint),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: inkFaint),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isSettled ? '' : formatted,
                style: AppTypography.amountLarge.copyWith(color: balanceColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _HubCard(
                onTap: () => context.push('/groups/${details.group.id}/members'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.people_outline, size: 20, color: ink),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Members', style: AppTypography.bodyEmphasis.copyWith(color: ink)),
                          const SizedBox(height: 2),
                          Text(
                            '${details.members.length} people',
                            style: AppTypography.caption.copyWith(color: inkFaint),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _HubCard(
                onTap: () => context.push('/groups/${details.group.id}/reports'),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.pie_chart_outline, size: 20, color: ink),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reports', style: AppTypography.bodyEmphasis.copyWith(color: ink)),
                          const SizedBox(height: 2),
                          Text('This month', style: AppTypography.caption.copyWith(color: inkFaint)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
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
      data: (items) {
        if (items.isEmpty) {
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

        final grouped = _groupByDate(items);
        final flatList = <dynamic>[];
        for (final entry in grouped.entries) {
          flatList.add(entry.key);
          flatList.addAll(entry.value);
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = flatList[index];
                if (item is String) return _buildDateHeader(context, item, isFirst: index == 0);
                return switch (item as GroupFeedItem) {
                  ExpenseFeedItem(:final expense) => ExpenseCard(
                      expense: expense,
                      currentUserId: currentUser?.id ?? '',
                      onTap: () => context.push('/transactions/expenses/${expense.id}'),
                    ),
                  SettlementFeedItem(:final settlement) => SettlementLogRow(
                      settlement: settlement,
                      currentUserId: currentUser?.id ?? '',
                    ),
                };
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

  Map<String, List<GroupFeedItem>> _groupByDate(List<GroupFeedItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<GroupFeedItem>>{};

    for (final item in items) {
      final date = item.date;
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
      (groups[label] ??= []).add(item);
    }
    return groups;
  }
}
