import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/group_model.dart';
import '../../data/group_repository.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/data/user_repository.dart';
import '../../../auth/data/user_model.dart';
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
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(groupDetailsProvider(widget.groupId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.userPlus,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              _showAddMemberModal(context, widget.groupId, isDark);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary[600],
          unselectedLabelColor: isDark
              ? AppColors.slate[400]
              : AppColors.slate[500],
          indicatorColor: AppColors.primary[600],
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (details) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildExpensesTab(context, details, isDark),
              _buildBalancesTab(context, details, isDark),
              _buildMembersTab(context, details, isDark),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(
            '/transactions/add-expense',
            extra: {'groupId': widget.groupId},
          );
        },
        backgroundColor: AppColors.primary[600],
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildExpensesTab(
    BuildContext context,
    GroupDetails details,
    bool isDark,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Search expenses...',
              hintStyle: TextStyle(
                color: isDark ? AppColors.slate[500] : AppColors.slate[400],
              ),
              prefixIcon: Icon(
                LucideIcons.search,
                size: 20,
                color: isDark ? AppColors.slate[400] : AppColors.slate[500],
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.slate[900] : AppColors.slate[50],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _ExpenseList(
            groupId: details.group.id,
            searchQuery: _searchQuery,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  void _showAddMemberModal(BuildContext context, String groupId, bool isDark) {
    final searchController = TextEditingController();
    final emailController = TextEditingController();
    bool isSearching = false;
    bool isInviting = false;
    List<User> searchResults = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.slate[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final viewInsets = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(
                bottom: viewInsets,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Member',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.slate[900],
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x, color: isDark ? AppColors.slate[400] : AppColors.slate[500]),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Search by name or email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.slate[300] : AppColors.slate[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: TextStyle(color: isDark ? AppColors.slate[500] : AppColors.slate[400]),
                              filled: true,
                              fillColor: isDark ? AppColors.slate[800] : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.slate[700]! : AppColors.slate[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.slate[700]! : AppColors.slate[300]!,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? AppColors.slate[800] : AppColors.slate[100],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: isSearching 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : Icon(LucideIcons.search, color: isDark ? AppColors.slate[300] : AppColors.slate[700]),
                          onPressed: () async {
                            if (searchController.text.trim().isEmpty) return;
                            setState(() => isSearching = true);
                            try {
                              final results = await ref.read(userRepositoryProvider).searchUsers(searchController.text.trim());
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
                    if (searchResults.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.slate[800] : AppColors.slate[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          separatorBuilder: (context, index) => Divider(color: isDark ? AppColors.slate[700] : AppColors.slate[200], height: 1),
                          itemBuilder: (context, index) {
                            final user = searchResults[index];
                            final displayName = user.firstName.isEmpty ? user.email.split('@').first : '${user.firstName} ${user.lastName}';
                            return ListTile(
                              title: Text(displayName, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14)),
                              subtitle: Text(user.email, style: TextStyle(color: isDark ? AppColors.slate[400] : AppColors.slate[500], fontSize: 12)),
                              trailing: IconButton(
                                icon: Icon(LucideIcons.plus, color: AppColors.primary[600]),
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
                    const SizedBox(height: 24),
                    Divider(color: isDark ? AppColors.slate[700] : AppColors.slate[200]),
                    const SizedBox(height: 24),
                    Text(
                      'Or Invite by Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.slate[300] : AppColors.slate[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: 'friend@example.com',
                              hintStyle: TextStyle(color: isDark ? AppColors.slate[500] : AppColors.slate[400]),
                              filled: true,
                              fillColor: isDark ? AppColors.slate[800] : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.slate[700]! : AppColors.slate[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.slate[700]! : AppColors.slate[300]!,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: PrimaryButton(
                            text: '',
                            icon: LucideIcons.mail,
                            isLoading: isInviting,
                            onPressed: () async {
                              if (emailController.text.trim().isEmpty) return;
                              setState(() => isInviting = true);
                              try {
                                await ref.read(groupRepositoryProvider).inviteUser(groupId, emailController.text.trim());
                                if (context.mounted) {
                                  context.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Invitation sent!')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                }
                              } finally {
                                setState(() => isInviting = false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBalancesTab(
    BuildContext context,
    GroupDetails details,
    bool isDark,
  ) {
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
                    child: Text(
                      "Everyone is settled up! 🎉",
                      style: TextStyle(
                        color: isDark ? AppColors.slate[400] : AppColors.slate[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: details.debts.length,
              itemBuilder: (context, index) {
                final debt = details.debts[index];
                final fromUser = details.members.firstWhere(
                  (m) => m.id == debt.from,
                  orElse: () => GroupMember(id: '', username: 'Unknown', email: ''),
                );
                final toUser = details.members.firstWhere(
                  (m) => m.id == debt.to,
                  orElse: () => GroupMember(id: '', username: 'Unknown', email: ''),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.slate[800]! : AppColors.slate[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(child: Text(fromUser.displayName.isNotEmpty ? fromUser.displayName[0].toUpperCase() : '?')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${fromUser.displayName} owes ${toUser.displayName}",
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      Text(
                        "₹${debt.amount.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[400],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMembersTab(
    BuildContext context,
    GroupDetails details,
    bool isDark,
  ) {
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
        padding: const EdgeInsets.all(16),
        itemCount: details.members.length,
        itemBuilder: (context, index) {
          final member = details.members[index];
          final displayName = member.displayName;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary[100],
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: TextStyle(color: AppColors.primary[700]),
              ),
            ),
            title: Text(
              displayName,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            subtitle: Text(
              member.email,
              style: TextStyle(
                color: isDark ? AppColors.slate[400] : AppColors.slate[600],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExpenseList extends ConsumerWidget {
  final String groupId;
  final String searchQuery;
  final bool isDark;

  const _ExpenseList({
    required this.groupId,
    required this.searchQuery,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider("$groupId|$searchQuery"));
    final currentUser = ref.watch(authProvider).value;

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertCircle, color: Colors.red[400], size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load expenses',
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: TextStyle(color: isDark ? AppColors.slate[400] : AppColors.slate[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(groupExpensesProvider("$groupId|$searchQuery")),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (expenses) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(groupExpensesProvider("$groupId|$searchQuery"));
            ref.invalidate(groupDetailsProvider(groupId));
            try {
              await ref.read(groupExpensesProvider("$groupId|$searchQuery").future);
            } catch (_) {}
          },
          child: expenses.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.receipt,
                              size: 64,
                              color: isDark ? AppColors.slate[700] : AppColors.slate[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty
                                  ? 'No expenses recorded in this group yet.'
                                  : 'No expenses found matching "$searchQuery"',
                              style: TextStyle(
                                color: isDark ? AppColors.slate[500] : AppColors.slate[400],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ExpenseCard(
                        expense: expense,
                        currentUserId: currentUser?.id ?? '',
                        onTap: () {
                          context.push('/transactions/expenses/${expense.id}', extra: expense);
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
