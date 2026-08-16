import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/menu_button.dart';
import '../groups_provider.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groups'),
        actions: [
          AppIconButton(icon: Icons.add, onPressed: () => context.push('/groups/create')),
          const SizedBox(width: AppSpacing.xs),
          const MenuButton(),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: groupsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: 5,
          itemBuilder: (_, __) => const AppSkeletonRow(),
        ),
        error: (err, stack) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(groupsProvider),
        ),
        data: (groups) {
          if (groups.isEmpty) return _buildEmptyState(context);

          return RefreshIndicator(
            onRefresh: () => ref.read(groupsProvider.notifier).loadGroups(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _GroupRow(
                  name: group.name,
                  description: group.description,
                  memberCount: group.members.length,
                  onTap: () => context.push('/groups/${group.id}'),
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
      child: AppEmptyState(
        icon: Icons.people_outline,
        title: 'No groups yet',
        message: 'Create a group to start splitting bills.',
        actionLabel: 'Create New Group',
        onAction: () => context.push('/groups/create'),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.name,
    required this.description,
    required this.memberCount,
    required this.onTap,
  });

  final String name;
  final String description;
  final int memberCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.ink;
    final inkFaint = isDark ? AppColors.inkFaintDark : AppColors.inkFaint;
    final sunken = isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceSunken;
    final accent = AppColors.categoryAccent(name);

    return AppInteractiveCard(
      onTap: onTap,
      showChevron: true,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: accent.withValues(alpha: isDark ? 0.22 : 0.12), shape: BoxShape.circle),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTypography.cardHeading.copyWith(color: accent),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.cardHeading.copyWith(color: ink)),
                const SizedBox(height: 2),
                Text(
                  description.isNotEmpty ? description : 'No description',
                  style: AppTypography.bodyMuted.copyWith(color: inkFaint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(color: sunken, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Row(
              children: [
                Icon(Icons.people_outline, size: 13, color: inkFaint),
                const SizedBox(width: 4),
                Text('$memberCount', style: AppTypography.caption.copyWith(color: inkFaint, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
