import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/group_model.dart';
import '../../data/group_repository.dart';

// Helper Provider for details
final groupDetailsProvider = FutureProvider.family<GroupDetails, String>((
  ref,
  id,
) async {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupDetails(id);
});

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              // TODO: Implement Invite Member Logic
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
          // Navigate to Add Expense with strict group mode
          // We pass extra map or query params
          // context.push('/transactions/add-expense?groupId=${widget.groupId}');
          // For now just print
          print("Add Expense for Group ${widget.groupId}");
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
    return Center(child: Text("Expenses List Placeholder"));
  }

  Widget _buildBalancesTab(
    BuildContext context,
    GroupDetails details,
    bool isDark,
  ) {
    if (details.debts.isEmpty) {
      return Center(
        child: Text(
          "Everyone is settled up! 🎉",
          style: TextStyle(
            color: isDark ? AppColors.slate[400] : AppColors.slate[600],
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
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
              CircleAvatar(child: Text(fromUser.username[0].toUpperCase())),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${fromUser.username} owes ${toUser.username}",
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
    );
  }

  Widget _buildMembersTab(
    BuildContext context,
    GroupDetails details,
    bool isDark,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: details.members.length,
      itemBuilder: (context, index) {
        final member = details.members[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary[100],
            child: Text(
              member.username[0].toUpperCase(),
              style: TextStyle(color: AppColors.primary[700]),
            ),
          ),
          title: Text(
            member.username,
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
    );
  }
}
