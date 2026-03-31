import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';

import '../groups_provider.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groups'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.plus,
              color: isDark ? Colors.white : AppColors.slate[900],
            ),
            onPressed: () => context.push('/groups/create'),
          ),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (groups) {
          if (groups.isEmpty) return _buildEmptyState(context);

          return RefreshIndicator(
            onRefresh: () => ref.read(groupsProvider.notifier).loadGroups(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return GestureDetector(
                  onTap: () => context.push('/groups/${group.id}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.slate[800]!
                            : AppColors.slate[200]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Group Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary[600]!,
                                Color(0xFF8b5cf6), // Violet
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              group.name.isNotEmpty
                                  ? group.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Group Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate[900],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                group.description.isNotEmpty
                                    ? group.description
                                    : 'No description',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.slate[400]
                                      : AppColors.slate[500],
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Members Count Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.slate[800]
                                : AppColors.slate[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.users,
                                size: 14,
                                color: isDark
                                    ? AppColors.slate[400]
                                    : AppColors.slate[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${group.members.length}',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.slate[300]
                                      : AppColors.slate[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          LucideIcons.chevronRight,
                          color: isDark
                              ? AppColors.slate[600]
                              : AppColors.slate[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary[50]!.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.users,
              size: 48,
              color: AppColors.primary[600],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Groups Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.slate[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a group to start splitting bills!',
            style: TextStyle(color: AppColors.slate[500], fontSize: 14),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: PrimaryButton(
              onPressed: () => context.push('/groups/create'),
              icon: LucideIcons.plus,
              text: 'Create New Group',
            ),
          ),
        ],
      ),
    );
  }
}
